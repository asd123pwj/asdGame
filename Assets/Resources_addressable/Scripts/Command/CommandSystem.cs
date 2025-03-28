using System.Collections.Generic;
using Sprache;
using UnityEngine;
using System.Globalization;
using System.Linq;

public class Command{
    public string name { get; set; }
    public Dictionary<string, object> args { get; set; } = new Dictionary<string, object>();
}

public static class argType{
    public static float toFloat(object value) => value is int i ? (float)i : (float)value;
}

public class CommandParser{ // Thank Deepseek
    static readonly Parser<string> Identifier =
        from first in Parse.Letter.Once()
        from rest in Parse.LetterOrDigit.Many()
        select new string(first.Concat(rest).ToArray());

    static readonly Parser<string> StringValue =
        (from open in Parse.Char('"')
         from content in Parse.CharExcept('"').Many().Text()
         from close in Parse.Char('"')
         select content)
        .Or(Parse.CharExcept(' ').Many().Text());

    static readonly Parser<object> NumberValue =
        Parse.DecimalInvariant
            .Select(s => s.Contains('.') 
                ? (object)float.Parse(s, CultureInfo.InvariantCulture) 
                : (object)int.Parse(s, CultureInfo.InvariantCulture));

    static readonly Parser<object> ParameterValue =
        NumberValue.Or(StringValue);

    static readonly Parser<KeyValuePair<string, object>> Parameter =
        from dash in Parse.Char('-')
        from name in Identifier
        from ws in Parse.WhiteSpace.AtLeastOnce()
        from value in ParameterValue
        select new KeyValuePair<string, object> ( name, value );

    public static readonly Parser<Command> Command =
        from name in Identifier
        from ws in Parse.WhiteSpace.AtLeastOnce()
        from parameters in Parameter.DelimitedBy(Parse.WhiteSpace.AtLeastOnce())
        select new Command { 
            name = name, 
            args = parameters.ToDictionary(p => p.Key, p => p.Value) 
        };

    public static Command parse(string input){
        return Command.Parse(input);
    }
}


public delegate void CommandHandler(Dictionary<string, object> args);
public class CommandSystem: BaseClass{
    static Dictionary<string, CommandHandler> handlers = new();

    public CommandSystem(){
        _sys._Msg._add_receiver(GameConfigs._sysCfg.Msg_command, _parse);
    }
    
    public void _parse(string command){
        Command cmd = CommandParser.parse(command);
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
