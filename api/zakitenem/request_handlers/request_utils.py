import logging

logger = logging.getLogger()

def out_error(response, error, code):
    logger.warning("Error: %s" % error)
    response.headers.add_header("Content-Type", "application/json")
    response.out.write('{"error":{"message":"%s", "user_message":"%s"}}' % (error, error))
    response.set_status(code)