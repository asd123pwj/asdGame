using System.Collections.Generic;
using Sprache;
using UnityEngine;
using System.Globalization;
using System.Linq;

public static class argType{
    public static float toFloat(object value) => value is int i ? (float)i : (float)value;
}

public class Command{
    public string name { get; set; }
    public Dictionary<string, object> args { get; set; } = new Dictionary<string, object>();
}

public class CommandParser{ // Thank Deepseek
    static readonly Parser<string> Identifier =
        from first in Parse.Letter.Once()
        from rest in Parse.LetterOrDigit.Or(Parse.Char('_')).Many() // 0.22.3, support '_' in "FROM_INPUT"
        select new string(first.Concat(rest).ToArray());

    static readonly Parser<string> StringValue =
        (from open in Parse.Char('"')
         from content in Parse.CharExcept('"').Many().Text()
         from close in Parse.Char('"')
         select content)
        .Or(Parse.CharExcept(' ').Many().Text());

    static readonly Parser<object> NumberValue =
        from sign in Parse.Char('-').Optional()
        from num in Parse.DecimalInvariant
        select ParseNumber(sign.IsDefined, num);

    private static object ParseNumber(bool hasMinus, string numStr){
        if (numStr.Contains('.')){
            float value = float.Parse(numStr, CultureInfo.InvariantCulture);
            return hasMinus ? -value : value;
        }
        else{
            int value = int.Parse(numStr, CultureInfo.InvariantCulture);
            return hasMinus ? -value : value;
        }
    }

    static readonly Parser<object> BooleanFlagValue =
        Parse.String("enable").Return((object)true)
            .Or(Parse.String("disable").Return((object)false));

    static readonly Parser<object> ParameterValue =
        BooleanFlagValue
            .Or(NumberValue)
            .Or(StringValue)
            .Or(Parse.Return((object)true));

    static readonly Parser<KeyValuePair<string, object>> Parameter =
        from dash in Parse.String("--")
        from name in Identifier
        from value in 
            Parse.WhiteSpace.AtLeastOnce()
            .Then(_ => Parse.Not(Parse.String("--")).Then(_ => ParameterValue))
            .Or(Parse.Return((object)true))
        select new KeyValuePair<string, object> ( name, value );

    public static readonly Parser<Command> Command =
        from name in Identifier
        // from ws in Parse.WhiteSpace.AtLeastOnce()
        // from parameters in Parameter.DelimitedBy(Parse.WhiteSpace.AtLeastOnce())
        from parameters in 
            Parse.WhiteSpace.AtLeastOnce()  
                .Then(_ => Parameter.DelimitedBy(Parse.WhiteSpace.AtLeastOnce()))
            .Optional()                     
            .Select(opt => opt.IsDefined ? opt.Get() : Enumerable.Empty<KeyValuePair<string, object>>())
        select new Command { 
            name = name, 
            args = parameters.ToDictionary(p => p.Key, p => p.Value) 
        };

    public static Command parse(string input){
        if (input == "") return parse("NOCOMMAND");
        return Command.Parse(input);
    }
}


public delegate void CommandHandler(Dictionary<string, object> args);
public class CommandSystem: BaseClass{
    static Dictionary<string, CommandHandler> handlers = new();

    public CommandSystem(){
        _sys._Msg._add_receiver(GameConfigs._sysCfg.Msg_command, _execute);
    }
    
    public static void _execute(DynamicValue command){
        Command cmd = CommandParser.parse(command.get<string>());
        if (handlers.ContainsKey(cmd.name)){
            handlers[cmd.name](cmd.args);
        }
        else{
            Debug.Log($"No command: {cmd.name}");
        }
    }

    public static void _add(string name, CommandHandler handler){
        handlers.Add(name, handler);
    }
}
