(import os sys argparse json
  [http.server [*]]
  [github [Github]])
(require [hy.contrib.walk [let]])

;; Name of the environment variable containing
;; the access token for the GitHub API.
(setv GITHUB-ENV "GITHUB_ACCESS_TOKEN")

;; TODO don't use a global variabler for handler parameter.
;; I don't like class factories either though.
(setv webhook-secret None)
(setv github-api None)

(defclass GithubWebhookHandler [BaseHTTPRequestHandler]
  (defn handle-pr [self dict]
    (print dict)
    (if (= (get dict "action") "opened")
      (let [name (get (get dict "repository") "full_name")
            repo (.get-repo github-api name)
            pr   (.get-issue repo :number (get dict "number"))]
        (.create-comment pr "Some Comment"))))

  (defn handle-ping [self]
    (.send-response self 200)
    (.send-header self "Content-Type" "application/json")
    (.end-headers self))

  (defn do-POST [self]
    ;; TODO verify secret
    (let [con-len  (int (.get self.headers "Content-Length"))
         github-ev (.get self.headers "X-GitHub-Event")]
      ;; TODO refactor and make more readable
      (if (= github-ev "ping")
        (.handle-ping self)
        (if (or (is None con-len) (not (= github-ev "pull_request")))
          (.send-response self 400)
          (try
            (let [payload (json.loads (.read self.rfile con-len))]
              (.handle-pr self payload)
              (.send-response self 200))
            (except [json.decoder.JSONDecodeError]
            (.send-response self 400))))))
    (.end-headers self)))

(defn start-server [addr port secret]
  (setv webhook-secret secret)
  (.serve-forever
    (HTTPServer (, addr port) GithubWebhookHandler)))

(defmain [&rest args]
  (let [access-token (os.getenv "GITHUB_ACCESS_TOKEN")]
    (if (is None access-token)
      (do
        (print :file sys.stderr
          (.format "Environment variable '{}' is not set" GITHUB-ENV))
        (sys.exit 1))
      (do
        (global github-api)
        (setv github-api (Github access-token)))))

  (let [parser (argparse.ArgumentParser)]
    (parser.add-argument "secret" :type string
      :help "GitHub webhook secret, used for authorization")
    (parser.add-argument "-p" :type int :metavar "PORT"
      :default 80 :help "TCP port used by the webhook HTTP server")
    (parser.add-argument "-a" :type string :metavar "ADDR"
      :default "localhost" :help "Address the webhook HTTP server binds to")
    (let [args (parser.parse-args)]
      (start-server args.a args.p args.secret))))
