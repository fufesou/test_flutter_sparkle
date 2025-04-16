from http.server import SimpleHTTPRequestHandler, HTTPServer

class CustomHandler(SimpleHTTPRequestHandler):
    def guess_type(self, path):
        if path.endswith(".xml"):
            return "application/xml"
        return super().guess_type(path)

if __name__ == '__main__':
    HTTPServer(("0.0.0.0", 8080), CustomHandler).serve_forever()
