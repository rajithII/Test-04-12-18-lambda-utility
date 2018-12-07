#!/bin/bash      
#title          :build_lambda.sh
#description    :This script will build all lambdas/selected lambdas with the utility.
#author         :rajith.v@iinerds.com
#date           :06-12-2018
#version        :1.0    
#usage          :/bin/sh build_lambda.sh
#bash_version   :4.2.46(1)-release
#======================================================================================

#Update Lambda Alias with the new version created
update_lambda_alias () {
    echo "=============================================================="
    echo "repname: $repo_name"
    echo "lambdaname:$lambda_name"
    echo "handlername:$handler_name"
    echo "=============================================================="

    echo "Creating new version.."
    aws lambda publish-version --function-name $1 --region us-east-1  > version2.txt
    if [ $? -eq 0 ]
    then
        version2=$(cat version2.txt | grep "Version" | awk '{ print $2 }' | tr -d '",')       
        echo "Version created successfully!. New version is: '$version2' "        
        echo "Updating lambda alias...."        
        aws lambda update-alias --function-name $1 --name dev --function-version $version2 --region us-east-1 
        if [ $? -eq 0 ]
            then                
                echo "Updated 'Dev' alias with new version '$version2'"                
            else               
                echo "Error occured during update process of lambda alias!. Please fix the error and start over"                
        fi
    else        
        echo "Error occured during the creatioin of Version!. Please fix the error and start over"    
    fi
}

#Create Lambda Alias and update the alias with the new version
create_lambda_alias () {   
    echo "Creating new version.."   
    aws lambda publish-version --function-name $1 --region us-east-1  > version1.txt
    if [ $? -eq 0 ]
    then
        version1=$(cat version1.txt | grep "Version" | awk '{ print $2 }' | tr -d '",')           
        echo "Version created successfully!. New version is: '$version1' "       
        echo "Creating new lambda alias...."         
        aws lambda create-alias --function-name $1 --name dev --function-version $version1 --region us-east-1 
    if [ $? -eq 0 ]
        then               
            echo "Created lamda alias 'Dev' with the new version '$version1'"              
        else               
            echo "Error occured during the creation of lambda alias!. Please fix the error and start over"                
        fi
    else         
        echo "Error occured during the creatioin of Version!. Please fix the error and start over"        
    fi
}


#Check Lambda Alias
check_lambda_alias () {
    alias=$(aws lambda list-aliases --function-name $1 --region us-east-1  | grep -i name | grep dev | awk '{ print $2}' | tr -d ',"')
    if [ "$alias" == "dev" ]
    then 
        update_lambda_alias $1 
    else
        create_lambda_alias $1
    fi
}


#Create new lambda function 
create_lambda () {    
    echo "Creating new lambda with name '$1' is in progress"     
    aws lambda create-function --function-name $1 --runtime java8 --handler $handler_name --role arn:aws:iam::902849442700:role/LambdaFullAccess --zip-file fileb://./target/demo-1.0.0.jar --region us-east-1 
    if [ $? -eq 0 ]
    then            
        echo "Lambda function: '$1' has been created successfully"        
        create_lambda_alias $1
    else
        echo "Error occured during the creation of lambda function!. Please fix the errors and start over!"
    fi    
}


#Update lambda function
update_lambda () {     
    echo "Update porcess of lambda function: '$1' is in progress"      
    aws lambda update-function-code --function-name $1 --zip-file fileb://./target/demo-1.0.0.jar --region us-east-1 
    if [ $? -eq 0 ]
    then             
        echo "Update process of lambda function: '$1' has been completed"            
        check_lambda_alias $1
    else        
        echo "Error occured during the lambda update process!. Please fix the errors and start over!"        
    fi  
}

#Check whether lambda function exist or not
check_lambda_exist () {
    check_flag=0     
    echo "Searching for '$1'"       
    var=$(aws lambda list-functions --region us-east-1  | grep -i functionname | awk '{ print $2 }' | tr -d '",')
    for name in `echo $var`
    do 
	        if [ "$name" == "$1" ]
	        then                
		        echo "Found lambda function:'$name'"               
                check_flag=1
                update_lambda $1
	        fi
    done
    if [ $check_flag -eq 0 ]
    then
        create_lambda $1
    fi        
}

#Build lambda function
build_lambda (){    
    echo "---------------------------------------"
    echo "handler name : $handler_name"
    echo "---------------------------------------"
    echo "Building '$lambda_name' with utility jar"    
    cd $1
    source /etc/profile.d/maven.sh
    mvn package -DskipTests=true
    if [ $? -eq 0 ]
    then        
        echo "Build of '$2' with utility jar has been completed successfully"        
        check_lambda_exist $2 
    else        
        echo "Error during the lambda build with utility jar. Please fix the error and start over!"        
    fi
    cd ..
}

#This will accept a repo parameter from jenkins and call corresponding lambda function to build.
selective_build () {
    echo $Name | sed -n 1'p' | tr ',' '\n' | while read word; do
    for line in `cat lambdalist.txt`
        do       
            repo_name=$(echo "$line" | cut -d':' -f1)
            lambda_name=$(echo "$line" | cut -d':' -f2)
            handler_name=$(echo "$line" | cut -d':' -f3)
            if [ "$lambda_name" == "$word" ];
            then
                echo "=============================================="
                echo "Building Lambda: $lambda_name"               
                echo "=============================================="
                build_lambda $repo_name $lambda_name
            fi 
        done
done
}

#Build all lambda functions
build_all () {
echo "====================================="
echo "Building All Lambda Functions"      
echo "====================================="
for line in `cat lambdalist.txt`
do       
    repo_name=$(echo "$line" | cut -d':' -f1)
    lambda_name=$(echo "$line" | cut -d':' -f2)  
    handler_name=$(echo "$line" | cut -d':' -f3)  
    echo "reponame: $repo_name"   
    echo "lambdaname: $lambda_name"   
    build_lambda $repo_name $lambda_name 
done
}

#Starting the build process
start () {
if [ "$Name" = "$All" ]
then
    build_all
else
    selective_build
fi
}

start


