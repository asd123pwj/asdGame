using System.Collections;
using System.Collections.Generic;
using System;
using System.Threading;
using UnityEngine;
using UnityEngine.Tilemaps;
using Cysharp.Threading.Tasks;
using Unity.VisualScripting;

public class ObjectMove{
    // ---------- Action ----------
    public Dictionary<string, ObjectAbilMoveBase> _moves = new();
    // ---------- Config ----------
    ObjectBase _Config;

    // ---------- Status ----------

    public ObjectMove(ObjectBase config){
        _Config = config;
        _Config._Move = this;
        init();
    }

    public void init(){
        _moves.Add("walk", new ObjectAbilMoveWalk(_Config, 0, 0, uses:-1));
        _moves.Add("jump", new ObjectAbilMoveJump(_Config, 0, 0.1f, uses:-1));
        _moves.Add("jump wall", new ObjectAbilMoveJumpWall(_Config, 0, 0.25f, uses:-1));
        // _moves.Add("fly", new ObjectAbilMoveFly(_Config, 5, 0.25f, duration:5f));
        _moves.Add("rush", new ObjectAbilMoveRush(_Config, 1, 0.25f, uses:-1));
        _moves.Add("teleport", new ObjectAbilMoveTeleport(_Config, 0, 0.1f, uses:-1));
    }

    public bool _walk(KeyPos input) { return move(input, "walk"); }
    public bool _jump(KeyPos input) { return move(input, "jump"); }
    public bool _jump_wall(KeyPos input) { return move(input, "jump wall"); }
    public bool _fly(KeyPos input) { return move(input, "fly"); }
    public bool _rush(KeyPos input) { return move(input, "rush"); }
    public bool _teleport(KeyPos input) { return move(input, "teleport"); }
    
    bool move(KeyPos input, string movement){
        if (_moves[movement]._act(input)){
            // if (_moves[movement]._wait > 0) foreach (var kvp in _moves) kvp.Value._act_wait(_moves[movement]._wait).Forget();
            // _Config._Movement.move(input);
            return true;
        }
        return false;
    }

    
}
