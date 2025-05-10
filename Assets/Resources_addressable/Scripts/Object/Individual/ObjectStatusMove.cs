using System.Collections;
using System.Collections.Generic;
using System;
using System.Threading;
using UnityEngine;
using UnityEngine.Tilemaps;
using Cysharp.Threading.Tasks;
using Unity.VisualScripting;


public class ObjectStatusMove{
    // ---------- Config ----------
    ObjectBase _Config;

    // ---------- Status ----------

    public bool _moving { get {return check_moving("moving"); } }
    public bool _movingX { get {return check_moving("x"); } }
    public bool _movingY { get {return check_moving("y"); } }
    public bool _movingUp { get {return check_moving("up"); } }
    public bool _movingDown { get {return check_moving("down"); } }
    public bool _movingLeft { get {return check_moving("left"); } }
    public bool _movingRight { get {return check_moving("right"); } }

    public ObjectStatusMove(ObjectBase config){
        // ---------- Config ----------
        _Config = config;
        _Config._StatusMove = this;
        // ---------- Init ----------
        init_trigger();
    }


    void init_trigger(){
        _Config._Contact._actions_float2Ground.Add(_on_float2Ground);
    }

    bool check_moving(string direction){
        if (direction == "moving") return _Config._rb.velocity.magnitude != 0;
        else if (direction == "x") return _Config._rb.velocity.x != 0;
        else if (direction == "y") return _Config._rb.velocity.y != 0;
        else if (direction == "up") return _Config._rb.velocity.y > 0;
        else if (direction == "down") return _Config._rb.velocity.y < 0;
        else if (direction == "left") return _Config._rb.velocity.y < 0;
        else if (direction == "right") return _Config._rb.velocity.x > 0;
        return false;
    }

    void _on_float2Ground(){
        _Config._Move._moves["jump"]._reset();
        _Config._Move._moves["jump wall"]._reset();
        // _Config._Move._moves["fly"]._reset();
    }

}
