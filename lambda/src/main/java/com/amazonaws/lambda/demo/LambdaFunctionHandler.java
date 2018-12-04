package com.amazonaws.lambda.demo;

import org.json.JSONObject;

import com.amazonaws.services.lambda.runtime.Context;
import com.amazonaws.services.lambda.runtime.RequestHandler;
import com.amazonaws.util.AppCoUtil;

public class LambdaFunctionHandler implements RequestHandler<Object, String> {

    @Override
    public String handleRequest(Object input, Context context) {
        context.getLogger().log("Input: " + input);

        try {
        	JSONObject inputParam = new JSONObject(input.toString());
        	String alias = inputParam.getString("alias");
        	AppCoUtil.chummaFunction();
        	JSONObject config = AppCoUtil.getConfigFromDynamoDB(alias);
        	System.out.println(config.toString());
        	return config.toString();
		} catch (Exception e) {
			// TODO: handle exception
		}
        
        // TODO: implement your handler
        return "Hello from Lambda!";
    }

}
