import json
import logging

def lambda_handler(event, context):
    # Setting log configuration
    logging.basicConfig(level = logging.DEBUG)
    logger = logging.getLogger()

    # Extractiong message
    expected_message = ["no", "yes"]
    message = event['Records'][0]['Sns']['Message']

    # Creating output
    output = "Received message: " + message
    logger.info(output)

    if message not in expected_message:
        raise Exception("Internal Server Error")
    else:
        return {
        'statusCode': 200,
        'body': json.dumps(output)
    }