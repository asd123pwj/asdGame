using System.Collections;
using System.Collections.Generic;
using System;
using System.Threading;
using UnityEngine;
using UnityEngine.Tilemaps;
using Cysharp.Threading.Tasks;

public class ObjectMonitor: BaseClass{
    // ---------- Status - Global ----------
    public ObjectBase _player;

    public ObjectMonitor(){
    }

    public ObjectBase _get_player() => _player;
    public void _set_player(ObjectBase player) {
        _player = player;
        _sys._CamMgr._set_camera_follow(player._self.transform);
    }


}
