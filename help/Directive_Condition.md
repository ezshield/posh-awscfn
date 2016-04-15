# **Condition** *(Add-CfnCondition)*

## SYNOPSIS
The optional Conditions section includes statements that define when a resource is created or when a property is defined.

## SYNTAX
```powershell
Add-CfnCondition [-ConditionName] <String> [-ConditionFunction] <Object> [<CommonParameters>]
```

## DESCRIPTION
As an example, you can compare whether a value is equal to another value. Based on the result of that condition, you can conditionally create resources.

You might use conditions when you want to reuse a template that can create resources in different contexts, such as a test environment versus a production environment. In your template, you can add an EnvironmentType input parameter, which accepts either prod or test as inputs. For the production environment, you might include Amazon EC2 instances with certain capabilities; however, for the test environment, you want to use reduced capabilities to save money. With conditions, you can define 
which resources are created and how they're configured for each environment type.

Conditions are evaluated based on input parameter values that you specify when you create or update a stack. Within each condition, you can reference another condition, a parameter value, or a mapping. After you define all your conditions, you can associate them with resources and resource properties in the Resources and Outputs sections of a template.

At stack creation or stack update, AWS CloudFormation evaluates all the conditions in your template before creating any resources. Any resources that are associated with a true condition are created. Any resources that are associated with a false condition are ignored.

Important
During a stack update, you cannot update conditions by themselves. You can update conditions only when you include changes that add, modify, or delete resources.


*How to Use Conditions Overview*

To conditionally create resources, you must include statements in at least three different sections of a template:

Parameters section
Define the input values that you want to evaluate in your conditions. Conditions will result in true or false based on values from these input parameter.

Conditions section
Define conditions by using the intrinsic condition functions. These conditions determine when AWS CloudFormation creates the associated resources.

Resources and Outputs sections
Associate conditions with the resources or outputs that you want to conditionally create. AWS CloudFormation creates entities that are associated with a true condition and ignores entities that are associated with a false condition. Use the Condition key and a condition's logical ID to associate it with a resource or output. To conditionally specify a property, use the Fn::If function. For more information, see Condition Functions.

You define all conditions in the Conditions section of a Template except for Fn::If conditions. You can use the Fn::If condition in the metadata attribute, update policy attribute, and property values in the Resources section and Outputs sections of a template.

## PARAMETERS
### -ConditionName &lt;String&gt;
For each Condition, you must declare a logical name. The logical name must be alphanumeric and unique among all logical names within the Template.
```
Required?                    true
Position?                    1
Default value
Accept pipeline input?       false
Accept wildcard characters?  false
```
 
### -ConditionFunction &lt;Object&gt;
Each condition declaration includes an intrinsic condition function that is evaluated when you create or update a stack.
```
Required?                    true
Position?                    2
Default value
Accept pipeline input?       false
Accept wildcard characters?  false
```

## INPUTS


## OUTPUTS


## NOTES


## EXAMPLES
