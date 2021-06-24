# https://docs.aws.amazon.com/ses/latest/DeveloperGuide/send-email-raw.html
# https://www.youtube.com/watch?v=SNc9qjLrSmM
# https://github.com/srcecde/aws-tutorial-code/blob/master/lambda/lambda_s3_event_ses_attach_email.py
from email.mime.multipart import MIMEMultipart
from email.mime.text import MIMEText
from email.mime.application import MIMEApplication
import logging
import datetime
import json
import traceback
import boto3

MSG_FORMAT = "%(asctime)s %(levelname)s %(name)s: %(message)s"
DATETIME_FORMAT = "%Y-%m-%d %H:%M:%S"
logging.basicConfig(format=MSG_FORMAT, datefmt=DATETIME_FORMAT)
logger = logging.getLogger(__name__)

logger.setLevel(logging.INFO)

ses = boto3.client("ses")
s3 = boto3.client("s3")
cloudwatch = boto3.client('cloudwatch')


def lambda_handler(event, context):
    sender = "test@test.com"
    to = "test2@test.com"
    bucket_name = "mybucket-1-2-3-4-5-6-7-8-9"
    obj_name = "watcherfile.txt"
    try:
        # for i in event["Records"]:
        #    action = i["eventName"]
        #    ip = i["requestParameters"]["sourceIPAddress"]
        #    bucket_name = i["s3"]["bucket"]["name"]
        #    object = i["s3"]["object"]["key"]
        logger.info(event)
        fileObj = s3.get_object(
            Bucket=bucket_name, Key=obj_name)
        file_content = fileObj["Body"].read()

        subject = 'Tesing email with attachment '
        body = """
        <br>
        This email is to notify you regarding {} event.
        The object {} is uploaded.
        Source IP: {}
        """.format("test", "object", "ip")

        msg = MIMEMultipart()
        msg["Subject"] = subject
        msg["From"] = sender
        msg["To"] = to

        body_txt = MIMEText(body, "html")

        attachment = MIMEApplication(file_content)
        attachment.add_header("Content-Disposition",
                              "attachment", filename=obj_name)

        msg.attach(body_txt)
        msg.attach(attachment)

        response = ses.send_raw_email(Source=sender, Destinations=[
                                      to], RawMessage={"Data": msg.as_string()})
        logger.info("Email sent")

        #Metric without dimension
        # https://stackify.com/custom-metrics-aws-lambda/
        cloudwatch.put_metric_data(
            MetricData=[
                {
                    'MetricName': 'EmailSentDimensionless',
                    'Unit': 'None',
                    'Value': 1,
                    'Timestamp': datetime.datetime.now()
                }
            ],
            Namespace='SendEmail'
        )

        #Metric with Dimension 
        cloudwatch.put_metric_data(
            MetricData=[
                {
                    'MetricName': 'EmailSentDimensions',
                    'Dimensions': [
                        {
                            'Name': 'Sender',
                            'Value': sender
                        },
                        {
                            'Name': 'Reciever',
                            'Value': to
                        },
                    ],
                    'Unit': 'None',
                    'Value': 1,
                    'Timestamp': datetime.datetime.now()
                }
            ],
            Namespace='SendEmail'
        )
    except Exception as ex:
        # Send some context about this error to Lambda Logs
        logger.error("Error while sending mail")
        logger.error("Exception with msg ::  {}".format(str(ex)))
        logger.error(traceback.format_exc())

    return {
        "statusCode": 200,
        "body": json.dumps(
            {
                "message": "Message sent",
                "to": to

            }
        ),
    }
