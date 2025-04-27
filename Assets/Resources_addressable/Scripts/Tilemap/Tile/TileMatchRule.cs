using System.Collections.Generic;
using UnityEngine;

public class TileRule{
    public string sub_ID;
    public Dictionary<TileRuleType, List<Vector2Int>> rule;
    public TileRule(string sub_ID, Dictionary<TileRuleType, List<Vector2Int>> rule){
        this.sub_ID = sub_ID;
        this.rule = rule;
    }

    public bool isMatch(TilemapTile tile){
        foreach (TileRuleType ruleType in rule.Keys){
            if(!isMatchRule(tile, ruleType, rule[ruleType])){
                return false;
            }
        }
        return true;
    }

    bool isMatchRule(TilemapTile tile, TileRuleType ruleType, List<Vector2Int> rule){
        foreach (Vector2Int offset in rule){
            if(!isMatchRule(tile, ruleType, offset)){
                return false;
            }
        }
        return true;
    }

    bool isMatchRule(TilemapTile tile, TileRuleType ruleType, Vector2Int offset){
        if(ruleType == TileRuleType.isNull){
            return !tile._neighbor_notEmpty[offset];
        }
        else if(ruleType == TileRuleType.notNull){
            return tile._neighbor_notEmpty[offset];
        }
        return false; // shouldn't happen, just placeholder
    }
}

public enum TileRuleType{
    isNull,
    notNull
}

public class TileMatchRule{
    public static List<Vector2Int> reference_pos = new(){
        new(-3, 1), new(-2, 1), new(-1, 1), new(0, 1), new(1, 1), new(2, 1), new(3, 1),
        new(-4, 0), new(-3, 0), new(-2, 0), new(-1, 0), new(1, 0), new(2, 0), new(3, 0), new(4, 0),
        new(0, -1)
    };
    public static List<TileRule> match_rules = new(){
        new("__L43", new (){ // 1
            {TileRuleType.isNull, new(){new(-4, 0), new(-3, 1), new(-2, 1), new(-1, 1), new(0, 1) }},
            {TileRuleType.notNull, new(){new(-3, 0), new(-2, 0), new(-1, 0), new(1, 0), new(2, 0), new(3, 0), new(4, 0) } }
        }),
        new("__L32", new (){ // 2
            {TileRuleType.isNull, new(){new(-3, 0), new(-2, 1), new(-1, 1), new(0, 1) }},
            {TileRuleType.notNull, new(){new(-2, 0), new(-1, 0), new(1, 0), new(2, 0), new(3, 0) } }
        }),
        new("__L32", new (){ // 3
            {TileRuleType.isNull, new(){new(-2, 0), new(-1, 1), new(0, 1), new(1, 1), new(3, 0) }},
            {TileRuleType.notNull, new(){new(-1, 0), new(1, 0), new(2, 0) } }
        }),
        new("__L32", new (){ // 4
            {TileRuleType.isNull, new(){new(-2, 0), new(-1, 1), new(0, 1) }},
            {TileRuleType.notNull, new(){new(-1, 0), new(1, 0), new(2, 0), new(1, 1) } }
        }),
        new("__L32", new (){ // 5
            {TileRuleType.isNull, new(){new(-2, 0), new(-1, 1), new(0, 1), new(4, 0) }},
            {TileRuleType.notNull, new(){new(-1, 0), new(1, 0), new(2, 0), new(3, 0) } }
        }),
        new("__L21", new (){ // 6
            {TileRuleType.isNull, new(){new(-2, 0), new(-1, 1), new(0, 1), new(1, 1) }},
            {TileRuleType.notNull, new(){new(-1, 0), new(1, 0), new(2, 0), new(3, 0), new(4, 0) } }
        }),
        new("__L10", new (){ // 7
            {TileRuleType.isNull, new(){new(-1, 0), new(0, 1), new(1, 1) }},
            {TileRuleType.notNull, new(){new(1, 0), new(2, 0), new(3, 0) } }
        }),
        new("__L3210", new (){ // 8
            {TileRuleType.isNull, new(){new(-1, 0), new(0, 1) }},
            {TileRuleType.notNull, new(){new(1, 0) } }
        }),
        new("__M", new (){ // 9
            {TileRuleType.isNull, new(){new(-1, 0), new(0, 1), new(1, 0) }},
        }),
        new("__R43", new (){ // 10
            {TileRuleType.isNull, new(){new(0, 1), new(1, 1), new(2, 1), new(3, 1), new(4, 0) }},
            {TileRuleType.notNull, new(){new(-4, 0), new(-3, 0), new(-2, 0), new(-1, 0), new(1, 0), new(2, 0), new(3, 0) } }
        }),
        new("__R32", new (){ // 11
            {TileRuleType.isNull, new(){new(0, 1), new(1, 1), new(2, 1), new(3, 0) }},
            {TileRuleType.notNull, new(){new(-3, 0), new(-2, 0), new(-1, 0), new(1, 0), new(2, 0) } }
        }),
        new("__R32", new (){ // 12
            {TileRuleType.isNull, new(){new(-2, 0), new(-1, 1), new(0, 1), new(1, 1), new(2, 0) }},
            {TileRuleType.notNull, new(){new(-2, 0), new(-1, 0), new(1, 0) } }
        }),
        new("__R32", new (){ // 13
            {TileRuleType.isNull, new(){new(0, 1), new(1, 1), new(2, 0) }},
            {TileRuleType.notNull, new(){new(-2, 0), new(-1, 0), new(-1, 1), new(1, 0) } }
        }),
        new("__R32", new (){ // 14
            {TileRuleType.isNull, new(){new(-4, 0), new(0, 1), new(1, 1), new(2, 0) }},
            {TileRuleType.notNull, new(){new(-3, 0), new(-2, 0), new(-1, 0), new(1, 0) } }
        }),
        new("__R21", new (){ // 15
            {TileRuleType.isNull, new(){new(-1, 1), new(0, 1), new(1, 1), new(2, 0) }},
            {TileRuleType.notNull, new(){new(-2, 0), new(-1, 0), new(1, 0) } }
        }),
        new("__R10", new (){ // 16
            {TileRuleType.isNull, new(){new(-1, 1), new(0, 1), new(1, 0)}},
            {TileRuleType.notNull, new(){new(-3, 0), new(-2, 0), new(-1, 0) } }
        }),
        new("__R3210", new (){ // 17
            {TileRuleType.isNull, new(){new(0, 1), new(1, 0) }},
            {TileRuleType.notNull, new(){new(-1, 0) } }
        }),
        new("__DL3210", new (){ // 18
            {TileRuleType.isNull, new(){new(-1, 0), new(0, -1) }},
            {TileRuleType.notNull, new(){new(0, 1), new(1, 0)} }
        }),
        new("__DR3210", new (){ // 19
            {TileRuleType.isNull, new(){new(0, -1), new(1, 0) }},
            {TileRuleType.notNull, new(){new(-1, 0), new(0, 1) } }
        }),
        new("__DM", new (){ // 20
            {TileRuleType.isNull, new(){new(-1, 0), new(0, -1), new(1, 0)}},
            {TileRuleType.notNull, new(){new(0, 1) } }
        }),
        new("__Full", new ())
    };


    public TileMatchRule(){

    }


    public static string match(TilemapTile tile){
    // public static string match(Vector3Int map_pos, LayerType layer){
        for(int i = 0; i < match_rules.Count; i++){
            TileRule rule = match_rules[i];
            if (rule.isMatch(tile)){
                return rule.sub_ID;
                // TilemapTile tile = TilemapTile._get(layer, map_pos);
                // tile._set_subID(rule.sub_ID);
                // // tile._update_tile();
                // break;
            }
        }
        return null;
    }
}