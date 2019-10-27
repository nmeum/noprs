#!/usr/bin/env hy

(import os sys argparse json hmac
  [http.server [*]]
  [github [Github]])
(require [hy.contrib.walk [let]])

(setv GITHUB-TOKEN  "GITHUB_ACCESS_TOKEN")   ;; ENV for API access token
(setv GITHUB-SECRET "GITHUB_WEBHOOK_SECRET") ;; ENV for webhook secret

(defclass GithubWebhookHandler [BaseHTTPRequestHandler]
  (defn handle-pr [self dict]
    (let [action (get dict "action")]
      (if (or (= action "opened")
              (and handle-reopened? (= action "reopened")))
        (let [name (get (get dict "repository") "full_name")
              repo (.get-repo github-api name)
              pr   (.get-issue repo :number (get dict "number"))]
          (.create-comment pr comment-text)
          (when close-issue?
            (.edit pr :state "closed"))))))

  (defn dispatch-event [self body]
    (try
      (let [body-json (json.loads body)
            event     (.get self.headers "X-GitHub-Event")]
        (cond
          [(= event "pull_request")
            (.handle-pr self body-json)]
          [(not (= event "ping"))
            (.send-error self 400 "Unsupported webhook event")])
        (.send-response self 200)
        (.end-headers self))
      (except [json.decoder.JSONDecodeError KeyError]
        (.send-error self 400 "Received invalid JSON document"))))

  (defn from-github? [self header data]
    (let [hmac-obj (hmac.new github-secret :msg data :digestmod "sha1")
          digest   (.hex (.digest hmac-obj))]
      (= (.format "sha1={}" digest) header)))

  (defn do-POST [self]
    (if (not (= "application/json" (.get self.headers "Content-Type")))
      (.send-error self 400 "Expected Content-Type application/json")
      (let [con-len (int (.get self.headers "Content-Length" :failobj "0"))]
        (let [body (.read self.rfile con-len)]
          (if (.from-github? self (.get self.headers "X-Hub-Signature") body)
            (.dispatch-event self body)
            (.send-error self 403 "HMAC digest validation failed")))))

    ;; Flush stderr, containing log messages created by http.server
    (sys.stderr.flush)))

(defmacro setg [name value]
  `(do
    (global ~name)
    (setv ~name ~value)))

(defn get-env [name]
  (let [value (os.getenv name)]
    (when (is None value)
      (print :file sys.stderr
        (.format "Environment variable '{}' is not set but required" name))
      (sys.exit 1))
    value))

(defmain [&rest args]
  (let [parser (argparse.ArgumentParser)
        token  (get-env GITHUB-TOKEN)
        secret (get-env GITHUB-SECRET)]
    (parser.add-argument "PATH" :type string
      :help "Path to markdown file containing comment text")
    (parser.add-argument "-p" :type int :metavar "PORT"
      :default 80 :help "TCP port used by the webhook HTTP server")
    (parser.add-argument "-c" :action "store_true"
      :help "Apart from adding a comment, also close the PR")
    (parser.add-argument "-r" :action "store_true"
      :help "Also handle reopened pull requests")
    (parser.add-argument "-a" :type string :metavar "ADDR"
      :default "localhost" :help "Address the webhook HTTP server binds to")

    (let [args (parser.parse-args)]
      (setg close-issue? args.c)
      (setg handle-reopened? args.r)
      (setg github-api (Github token))
      (setg github-secret (.encode secret))

      (with [f (open args.PATH)]
        (setg comment-text (.rstrip (.read f))))

      (.serve-forever
        (HTTPServer (, args.a args.p) GithubWebhookHandler)))))
