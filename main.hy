(import os sys argparse json
  [http.server [*]]
  [github [Github]])
(require [hy.contrib.walk [let]])

(setv GITHUB-TOKEN  "GITHUB_ACCESS_TOKEN")   ;; ENV for API access token
(setv GITHUB-SECRET "GITHUB_WEBHOOK_SECRET") ;; ENV for webhook secret

;; TODO don't use a global variabler for handler parameter.
;; I don't like class factories either though.
(setv webhook-secret None)
(setv github-api None)

(defclass GithubWebhookHandler [BaseHTTPRequestHandler]
  (defn handle-pr-json [self dict]
    (print dict)
    (if (= (get dict "action") "opened")
      (let [name (get (get dict "repository") "full_name")
            repo (.get-repo github-api name)
            pr   (.get-issue repo :number (get dict "number"))]
        (.create-comment pr "Some Comment")
        (.send-response self 200))))

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
    (let [event (.get self.headers "X-GitHub-Event")]
      (cond
        [(= event "ping") (.handle-ping self)]
        [(= event "pull_request") (.handle-pr self)]
        [True (.send-response self 400)]))
    (.end-headers self)))

(defn start-server [addr port secret]
  (setv webhook-secret secret)
  (.serve-forever
    (HTTPServer (, addr port) GithubWebhookHandler)))

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
    (parser.add-argument "-p" :type int :metavar "PORT"
      :default 80 :help "TCP port used by the webhook HTTP server")
    (parser.add-argument "-a" :type string :metavar "ADDR"
      :default "localhost" :help "Address the webhook HTTP server binds to")
    (let [args (parser.parse-args)]
      (global github-api) (setv github-api (Github token))
      (start-server args.a args.p secret))))
