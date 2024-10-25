using System.Collections.Generic;


public class Str2Offset{
    static Dictionary<string, int> str2offset = new Dictionary<string, int>();

    public static int _get(string str){
        if (!str2offset.ContainsKey(str)) {
            str2offset.Add(str, str.GetHashCode() % 1000000);
        }
        return str2offset[str];
        
    }
}