using System.Collections.Generic;


public class Str2Offset{
    static Dictionary<string, int> str2offset = new Dictionary<string, int>();
    static readonly object lockObject = new();

    public static int _get(string str){
        lock (lockObject) {
            if (!str2offset.ContainsKey(str)) {
                int hash = 0;
                for (int i=str.Length-1;  i >= 0; i--){
                    char c = str[i];
                    hash = (hash * 7 + c) & 0x7FFFFFFF;
                }
                str2offset.Add(str, hash);
            }
            return str2offset[str];
        }
    }
}