import logging

logger = logging.getLogger()

def out_error(response, error, status_code, http_code=0):
    if http_code == 0:
        http_code = 200
    logger.warning("Error: %s" % error)
    response.headers.add_header("Content-Type", "application/json")
    response.out.write('{"error_message":"%s", "error_code":"%s"}' % (error, status_code))
    response.set_status(http_code)
