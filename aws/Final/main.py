import boto3
import getbill as gbill
import os, json

# Document
s3BucketName = "invoice-storage-unifyed"
documentName = "documentimagejpg"
# documentName = "Donuts (1).jpg"


# Amazon Textract client
textract = boto3.client('textract')

# Call Amazon Textract
response = textract.detect_document_text(
    Document={
        'S3Object': {
            'Bucket': s3BucketName,
            'Name': documentName
        }
    })

#print(response)

# Print text
# print("\nText\n========")
text = ""
for item in response["Blocks"]:
    if item["BlockType"] == "LINE":
        # print ('\033[94m' +  item["Text"] + '\033[0m')
        text = text + " " + item["Text"]

# Amazon Comprehend client
comprehend = boto3.client('comprehend')

# Detect entities
titles = []
organization = ""
other_orgs = []
org_highest = 0
locations = []
quantities = []
other = []
date = []
people = []
commercial_items = []

#Special
invoice_number = []

entities =  comprehend.detect_entities(LanguageCode="en", Text=text)
print("\nEntities\n========")
for entity in entities["Entities"]:
    # print ("{}\t=>\t{}".format(entity["Type"], entity["Text"]))
    if entity["Type"] == "ORGANIZATION":

        # Include only the organization with the highest score
        if entity["Score"] > org_highest:
            org_highest = entity["Score"]
            organization = entity["Text"]
        
        if entity["Score"] > 0.5 and entity["Score"] < 0.8:
            other_orgs.append(entity["Text"])
    
    elif entity["Type"] == "LOCATION":
        if entity["Score"] > 0.3:
            locations.append(entity["Text"])
    elif entity["Type"] == "TITLE":
        titles.append(entity["Text"])
    elif entity["Type"] == "QUANTITY":
        if entity["Score"] > 0.4:
            quantities.append(entity) #The Whole Entity
    elif entity["Type"] == "OTHER":
        other.append(entity["Text"])
    elif entity["Type"] == "DATE":
        date.append(entity["Text"])
    elif entity["Type"] == "PERSON":
        people.append(entity["Text"])
    elif entity["Type"] == "COMMERCIAL_ITEM":
        commercial_items.append(entity["Text"])
    

print()
print(organization)

print("\nLocation: \n{}".format("\n".join(locations)))

print()

print("Date: {}".format(",".join(date)))

print()

print("Items: \n{}".format("\n".join(commercial_items)))
print("\n".join(other_orgs))

print()

#TODO: Use Amazon Textract to specifically get the BILL AMOUNT, using Key:Value pair thing like I was trying earlier
# Interesting: We used the mode of the bill amounts, because in any bill, there is more than one total amount. Like, total,
# subtotal, amount, net amount, etc.

#Download the file for the getbill module
s3 = boto3.client('s3')
s3.download_file(s3BucketName, documentName, documentName)

#We shall get filnames without an extention so we need to add it manually
os.rename(documentName, documentName + '.jpg')
documentName += ".jpg"

bill_and_invoice = gbill.main(documentName)
bill = bill_and_invoice[0]
invoice = bill_and_invoice[1]

print()

print("Invoice Number: {}".format("".join(invoice)))

print()

print("Bill Amount: {}".format("".join(bill)))

#Make an object and put all this data into it. Then output JSON to a temperory storage.
finalobj = {
    "organization": organization,
    "date": date,
    "locations": locations,
    "bill_amount": "".join(bill),
    "invoice": "".join(invoice),
    "other_orgs" : other_orgs,
    "commercial_items": commercial_items,
    "people": people,
    "other": other,
    "titles": titles,
    "quantities": quantities
}

with open('output.json', 'w+') as f:
    f.write(json.dumps(finalobj))
    f.close()

print("output.json created locally.")

#Upload the Output.JSON file directly to the S3 Bucket
s3 = boto3.client('s3')
with open('output.json', 'rb') as f:
    s3.upload_fileobj(f, s3BucketName, 'output.json')

print("Finished uploading output.json to the bucket")