import boto3
import sys
import re
import json, os, time
from scipy import stats

def get_kv_map(file_name):

    with open(file_name, 'rb') as file:
        img_test = file.read()
        bytes_test = bytearray(img_test)
        print('Image loaded for getting Bill Amount & Invoice Number', file_name)

    # process using image bytes
    client = boto3.client('textract')
    response = client.analyze_document(Document={'Bytes': bytes_test}, FeatureTypes=['FORMS'])

    # Get the text blocks
    blocks=response['Blocks']
    

    # get key and value maps
    key_map = {}
    value_map = {}
    block_map = {}
    for block in blocks:
        block_id = block['Id']
        block_map[block_id] = block
        if block['BlockType'] == "KEY_VALUE_SET":
            if 'KEY' in block['EntityTypes']:
                key_map[block_id] = block
            else:
                value_map[block_id] = block

    return key_map, value_map, block_map


def get_kv_relationship(key_map, value_map, block_map):
    kvs = {}
    for block_id, key_block in key_map.items():
        value_block = find_value_block(key_block, value_map)
        key = get_text(key_block, block_map)
        val = get_text(value_block, block_map)
        kvs[key] = val
    return kvs


def find_value_block(key_block, value_map):
    for relationship in key_block['Relationships']:
        if relationship['Type'] == 'VALUE':
            for value_id in relationship['Ids']:
                value_block = value_map[value_id]
    return value_block


def get_text(result, blocks_map):
    text = ''
    if 'Relationships' in result:
        for relationship in result['Relationships']:
            if relationship['Type'] == 'CHILD':
                for child_id in relationship['Ids']:
                    word = blocks_map[child_id]
                    if word['BlockType'] == 'WORD':
                        text += word['Text'] + ' '
                    if word['BlockType'] == 'SELECTION_ELEMENT':
                        if word['SelectionStatus'] == 'SELECTED':
                            text += 'X '    

                                
    return text


def print_kvs(kvs):
    for key, value in kvs.items():
        print(key, ":", value)


def search_value(kvs, search_key):
    for key, value in kvs.items():
        if re.search(search_key, key, re.IGNORECASE):
            return value

def main(file_name):

    key_map, value_map, block_map = get_kv_map(file_name)

    # Get Key Value relationship
    kvs = get_kv_relationship(key_map, value_map, block_map)
    # print("\n\n== FOUND KEY : VALUE pairs ===\n")
    # print_kvs(kvs)

    #BILL AMOUNT SEARCH
    search_keys = ["net", "amount", "Subtotal", "subtotal", "total", "Total", "pay", "card", "cash", "Cash", "Net Amount", "Net Total", "Pay", "Payment", "Amount", "Grand Total", "Grand Total: Rs", "Credit"]
    bill_amounts = []

    for key in search_keys:
        search_result = search_value(kvs, key)
        if search_result is not None:
            bill_amounts.append(search_result)
    
    #INVOICE SEARCH
    invoice_keys = ["InvNo", "Inv No", "Bill No", "Bill No.", "Invoice Number"]
    invoices = []

    for key in invoice_keys:
        invoice_result = search_value(kvs, key)
        if invoice_result is not None:
            invoices.append(invoice_result)
    
    bill = 0
    invoice = ""

    #Check the MODE of the list
    bill = stats.mode(bill_amounts)[0]
    #Checking Mode for Invoice too just in case
    invoice = stats.mode(invoices)[0]

    os.remove(file_name)

    return [bill, invoice]


# if __name__ == "__main__":
#     file_name = sys.argv[1]
#     main(file_name)