using System.Collections;
using System.Collections.Generic;
using System;
using System.Threading;
using UnityEngine;
using UnityEngine.Tilemaps;
using Cysharp.Threading.Tasks;

public class ObjectSpawn{
    GameConfigs GCfg;
    MaterialSystem MatSys { get => GCfg._MatSys; }
    // ObjectList _object_list;

    public ObjectSpawn(GameConfigs game_configs){
        GCfg = game_configs;
        // _object_list = object_list;
    }

    public void _instantiate(string name, Vector2 position){
        // GameObject obj = _object_list._name2object[name];
        GameObject obj = MatSys._obj._get_prefab(name);
        // ObjectTags tags = _object_list._objects_info.objects[name].tags;
        obj = UnityEngine.Object.Instantiate(obj, position, Quaternion.identity);
        // obj.GetComponent<ObjectIndividual>()._info = _object_list._objects_info.objects[name];
        ObjectConfig Base = new(obj, MatSys._obj._get_info(name));
        // GCfg._ObjSys._obj2base.Add(obj, Base);
        // GCfg._ObjSys._runtimeID2base.Add(Base._runtimeID, Base);
        // obj.GetComponent<ObjectIndividual>()._info = MatSys._obj._get_info(name);
        GCfg._ObjSys.player = Base;
    }

}
