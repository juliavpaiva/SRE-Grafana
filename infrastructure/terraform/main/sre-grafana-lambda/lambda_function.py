import json

def lambda_handler(event, context):
    expected_message = ["no", "yes"]
    message = event['Records'][0]['Sns']['Message']

    output = "Received message: " + message
    print(output)

    if message not in expected_message:
        raise Exception("Internal Server Error")
    else:
        return {
        'statusCode': 200,
        'body': json.dumps(output)
    }