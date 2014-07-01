import error_definitions
import constants
import logging
import json

def handle_404(request, response, exception):
    logging.exception(exception)
    response.headers.add_header("Content-Type", "application/json")
    resp = {constants.error_key: error_definitions.msg_no_such_page}
    response.write(json.dumps(resp))
    response.set_status(404)

def handle_405(request, response, exception):
    logging.exception(exception)
    response.headers.add_header("Content-Type", "application/json")
    resp = {constants.error_key: error_definitions.msg_no_such_page}
    response.write(json.dumps(resp))
    response.set_status(405)    

def handle_500(request, response, exception):
    logging.exception(exception)
    resp = {constants.error_key: error_definitions.msg_server_error}
    response.write(json.dumps(resp))
    response.set_status(500)
    