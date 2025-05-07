using System.Collections;
using System.Collections.Generic;
using System;
using System.Threading;
using UnityEngine;
using UnityEngine.Tilemaps;
using Cysharp.Threading.Tasks;

public class ObjectMonitor: BaseClass{
    // ---------- Status - Global ----------
    public ObjectConfig _player;

    public ObjectMonitor(){
    }

    public ObjectConfig _get_player() => _player;
    public void _set_player(ObjectConfig player) {
        _player = player;
        _sys._CamMgr._set_camera_follow(player._self.transform);
    }


}
