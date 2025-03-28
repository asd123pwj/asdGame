using System.Collections.Generic;
using Sprache;
using UnityEngine;
using System.Globalization;
using System.Linq;

public class Command{
    public string name { get; set; }
    public List<Parameter> args { get; set; } = new List<Parameter>();
}

public class Parameter{
    public string key { get; set; }
    public object value { get; set; }
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
                ? (object)double.Parse(s, CultureInfo.InvariantCulture) 
                : (object)int.Parse(s, CultureInfo.InvariantCulture));

    static readonly Parser<object> ParameterValue =
        NumberValue.Or(StringValue);

    static readonly Parser<Parameter> Parameter =
        from dash in Parse.Char('-')
        from name in Identifier
        from ws in Parse.WhiteSpace.AtLeastOnce()
        from value in ParameterValue
        select new Parameter { key = name, value = value };

    public static readonly Parser<Command> Command =
        from name in Identifier
        from ws in Parse.WhiteSpace.AtLeastOnce()
        from parameters in Parameter.Many()
        select new Command { name = name, args = parameters.ToList() };

    public static Command parse(string input){
        return Command.Parse(input);
    }
}


public class CommandSystem: BaseClass{
    public CommandSystem(){
        _sys._Msg._add_receiver(GameConfigs._sysCfg.Msg_command, _parse);
    }
    
    public void _parse(string command){
        Command result = CommandParser.parse(command);
        Debug.Log($"Command: {result.name}");
        foreach (var arg in result.args){
            Debug.Log($"{arg.key} = {arg.value}");
        }
    }
}
