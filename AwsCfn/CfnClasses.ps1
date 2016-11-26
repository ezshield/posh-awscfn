<#
These classes are used to support strongly-typed cmdlet parameters, yet allow
for flexibility to pass in complex structures in lieu of a strict type, such
as a hashtable that defines a CFN function invocation or resource reference
#>

## Conditional type definitions based on:
##    http://stackoverflow.com/a/22156833/5428506

if (-not ([System.Management.Automation.PSTypeName]'CfnValue').Type)
{
    Add-Type -Language CSharp -TypeDefinition @"
    public abstract class CfnValue
    {
        public abstract object GetValue();

        public static object GetValue(CfnValue v)
        {
            return v == null ? null : v.GetValue();
        }
    }

    public class CfnDynaValue : CfnValue
    {
        private object _value;

        public CfnDynaValue(object value)
        {
            _value = value;
        }

        public override object GetValue()
        {
            return _value;
        }
    }

    public class CfnParam<T> : CfnValue
    {
        private object _value;

        public CfnParam(T value)
        {
            _value = value;
        }

        private CfnParam(object value)
        {
            _value = value;
        }

        public override object GetValue()
        {
            return _value;
        }

        public static implicit operator CfnParam<T>(T value)
        {
            return new CfnParam<T>(value);
        }

        public static implicit operator CfnParam<T>(CfnDynaValue value)
        {
            return new CfnParam<T>(value == null ? null : value.GetValue());
        }
    }
"@
}
