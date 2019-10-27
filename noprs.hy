(import os sys argparse json
  [http.server [*]]
  [github [Github]])
(require [hy.contrib.walk [let]])

(setv GITHUB-TOKEN  "GITHUB_ACCESS_TOKEN")   ;; ENV for API access token
(setv GITHUB-SECRET "GITHUB_WEBHOOK_SECRET") ;; ENV for webhook secret

(defclass GithubWebhookHandler [BaseHTTPRequestHandler]
  (defn handle-pr-json [self dict]
    (if (= (get dict "action") "opened")
      (let [name (get (get dict "repository") "full_name")
            repo (.get-repo github-api name)
            pr   (.get-issue repo :number (get dict "number"))]
        (.create-comment pr comment-text)
        (when close-issue?
          (.edit pr :state "closed"))))
      (.send-response self 200))

  (defn handle-pr [self]
    (let [con-len (int (.get self.headers "Content-Length"))]
      (if (is None con-len)
        (.send-response self 400)
        (try
          (.handle-pr-json self (json.loads (.read self.rfile con-len)))
          (except [json.decoder.JSONDecodeError]
            (.send-response self 400))))))

  (defn handle-ping [self]
    (.send-response self 200))

  (defn do-POST [self]
    (if (not (= "application/json" (.get self.headers "Content-Type")))
      (.send-response self 400))
    (let [event (.get self.headers "X-GitHub-Event")]
      (cond
        [(= event "ping") (.handle-ping self)]
        [(= event "pull_request") (.handle-pr self)]
        [True (.send-response self 400)]))
    (.end-headers self)))

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
    (parser.add-argument "-a" :type string :metavar "ADDR"
      :default "localhost" :help "Address the webhook HTTP server binds to")

    (let [args (parser.parse-args)]
      (setg close-issue? args.c)
      (setg github-api (Github token))

      (with [f (open args.PATH)]
        (setg comment-text (.rstrip (.read f))))

      (.serve-forever
        (HTTPServer (, args.a args.p) GithubWebhookHandler)))))
