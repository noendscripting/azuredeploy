import csv
filename='c:\\temp\\gelinuxoms.csv'
osdata=list()
osdataHeaders=['subscriptionName','resourceGroup','resourceType','resourceName','resourceId','osdata']
osdata.append(osdataHeaders)
with open(filename) as omsreport:
    reader=csv.reader(omsreport)
    header=next(omsreport)
    for row in reader:
        print(row[0])
        subscription=row[0]
        resourcegroup=row[1]
        vnname=row[2]
        resourceId=row[3]
        result=$(az vm run-command invoke --command-id RunShellScript --scripts 'cat /etc/os-release | grep PRETTY_NAME' --query 'value[0].message' --ids resourceId)
        item=[subscription,resourcegroup,vnname,resourceId,result]
        osdata.append(item)
        result=None
        item=None

print(osdata)

