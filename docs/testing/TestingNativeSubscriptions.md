# Testing Native Subscriptions

In order to test Native Subscriptions in development, you will need to configure your fake server before side loading your app. In order to do this you will need to turn on the fake server and update the files within the _csfake_ folder.

1. To turn on the fake server go into _source/main.brs_. You will want to go inside `SetHomeScene()` and update the line with `' m.store.FakeServer(true)` to `m.store.FakeServer(true)`. Removing the apostrophe will uncomment the line and causing the app to run a fake server in the side loaded app.
2. Next you will want to update the files inside _csfake_. These files will contain the mocked responses for the faked store when you are running the side loaded app. To test the native subscriptions, you will need to replace the __code__ for the products inside the XML files with a valid __subscription plan id__ from the platform. The native subscription's code needs to match a subscription plan id so it integrates smoothly with the Zype platform and subscriptions via device linking.

    - To get the subscription plan id, go to the __Zype platform -> Make Money -> Subscription Plans__ (or get there directly with [https://admin.zype.com/plans](https://admin.zype.com/plans)) and select one of the subscription plans you are trying to test. Get that subscription plan's id and update the files inside _csfake_.
    - __Note:__ Just like the code should match the subscription plan id in development, it should match in production. If you are responsible for submissions as well, the code is called __identifier__ when you are creating the in app purchase.

    __CheckOrder.xml__ should look something like this:

    ~~~XML
    <orderItem>
            <amount>$1.99</amount>
            <code>MonthlySubscriptionPlanId</code>
            <description>Monthly Subcription</description>
            <name>Monthly Subscription</name>
            <purchaseId i:nil="true"/>
            <qty>1</qty>
            <total>$1.99</total>
    </orderItem>
    ~~~

    __GetCatalog.xml__ should look something like this:

    ~~~XML
    <products>
            <product xmlns="">
                    <HDPosterUrl i:nil="true"/>
                    <SDPosterUrl i:nil="true"/>
                    <code>MonthlySubscriptionPlanId</code>
                    <cost>$1.99</cost>
                    <description/>
                    <expirationDate i:nil="true"/>
                    <freeTrialQuantity>0</freeTrialQuantity>
                    <freeTrialType>None</freeTrialType>
                    <fulfills xmlns:a="http://schemas.microsoft.com/2003/10/Serialization/Arrays"/>
                    <inStock>true</inStock>
                    <maxQty>8</maxQty>
                    <name>Monthly Subscription</name>
                    <productType>MonthlySub</productType>
                    <purchaseDate>0001-01-01T00:00:00</purchaseDate>
                    <purchaseId i:nil="true"/>
                    <qty>1</qty>
                    <renewalDate i:nil="true"/>
                    <upsellProduct i:nil="true"/>
            </product>
            <product xmlns="">
                    <HDPosterUrl i:nil="true"/>
                    <SDPosterUrl i:nil="true"/>
                    <code>YearlySubscriptionPlanId</code>
                    <cost>$19.99</cost>
                    <description/>
                    <expirationDate i:nil="true"/>
                    <freeTrialQuantity>0</freeTrialQuantity>
                    <freeTrialType>None</freeTrialType>
                    <fulfills xmlns:a="http://schemas.microsoft.com/2003/10/Serialization/Arrays"/>
                    <inStock>true</inStock>
                    <maxQty>8</maxQty>
                    <name>Yearly Subscription</name>
                    <productType>YearlySub</productType>
                    <purchaseDate>0001-01-01T00:00:00</purchaseDate>
                    <purchaseId i:nil="true"/>
                    <qty>1</qty>
                    <renewalDate i:nil="true"/>
                    <upsellProduct i:nil="true"/>
            </product>
    </products>
    ~~~

    Update all the files in a similar way and replace code with the subscription plan id.

3. If you side load the app with products uncommented inside __GetPurchases.xml__, the app will behave as if the user reopened the app with a valid native subscription. To simulate the flow of purchasing a native subscription, you will want to leave the native subscription products commented before side loading (they are commented by default).
