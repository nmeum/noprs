(import argparse json
  [http.server [*]])
(require [hy.contrib.walk [let]])

;; TODO don't use a global variable for the webhook secret.
;; I don't like class factories either though.
(setv webhook-secret None)

(defclass GithubWebhookHandler [BaseHTTPRequestHandler]
  (defn do-POST [self]
    ;; TODO verify secret
    (let [con-len (int (.get self.headers "Content-Length"))]
      (if (is None con-len)
        (.send-response self 400)
        (try
          (let [payload (json.loads (.read self.rfile con-len))]
            (print payload)
            (.send-response self 200))
          (except [json.decoder.JSONDecodeError]
            (.send-response self 400)))))
    (.end-headers self)))

(defn start-server [addr port secret]
  (setv webhook-secret secret)
  (.serve-forever
    (HTTPServer (, addr port) GithubWebhookHandler)))

(defmain [&rest args]
  (let [parser (argparse.ArgumentParser)]
    (parser.add-argument "secret" :type string
      :help "GitHub webhook secret, used for authorization")
    (parser.add-argument "-p" :type int :metavar "PORT"
      :default 80 :help "TCP port used by the webhook HTTP server")
    (parser.add-argument "-a" :type string :metavar "ADDR"
      :default "localhost" :help "Address the webhook HTTP server binds to")
    (let [args (parser.parse-args)]
      (start-server args.a args.p args.secret))))
