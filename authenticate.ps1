# Authenticate to Azure using User Credentials
az login

# Set the subscription
az account set --subscription "Microsoft Sponsored - 1"


# create PostgreSQL server using 
az postgres flexible-server create --resource-group demoresourcegroup --name demoserverpostgres --vnet demoappvnet --location australiaeast