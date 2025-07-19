import boto3
import json
import datetime

s3_client = boto3.client('s3')

def lambda_handler(event, context):
    print("Event received:", json.dumps(event))
    today = datetime.datetime.utcnow().date()
    count = len(event['Records'])
    
    report_content = f"Date: {today}\nFiles Processed: {count}\n"
    
    s3_client.put_object(
        Bucket=event['Records'][0]['s3']['bucket']['name'],
        Key=f"reports/report_{today}.txt",
        Body=report_content.encode('utf-8')
    )
    print(f"Report generated for {today}")
    return {
        'statusCode': 200,
        'body': json.dumps('Report generated.')
    }
