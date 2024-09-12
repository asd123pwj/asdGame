using System.Collections.Generic;
using System.IO;
using Newtonsoft.Json;
using UnityEngine;
using UnityEngine.AddressableAssets;
using UnityEngine.ResourceManagement.AsyncOperations;
using Cysharp.Threading.Tasks;
using Unity.VectorGraphics;

public struct PhysicsMaterialInfo{
    public float friction;
    public float bounciness;
}

public struct PhysicsMaterialsInfo{
    public string version;
    public Dictionary<string, PhysicsMaterialInfo> items;
}

public class PhysicsMaterialManager: BaseClass{
    public PhysicsMaterialsInfo _infos;
    public Dictionary<string, PhysicsMaterial2D> _ID2PhysicsMaterial2D = new();

    public PhysicsMaterialManager(){
        load_all();
    }

    public bool _check_info_initDone(){
        return !(_infos.version == null);
    }

    public bool _check_exist(string ID){
        return _infos.items.ContainsKey(ID);
    }

    public bool _check_loaded(string ID){
        return _ID2PhysicsMaterial2D.ContainsKey(ID);
    }

    public PhysicsMaterial2D _get_phyMat(string ID){
        return _ID2PhysicsMaterial2D[ID];
    }

    void load_item(string ID){
        PhysicsMaterial2D item = new() { 
            friction = _infos.items[ID].friction,
            bounciness = _infos.items[ID].bounciness
        };
        _ID2PhysicsMaterial2D.Add(ID, item);
        Debug.Log(ID);
    }

    void load_all(){
        string jsonText = File.ReadAllText(_GCfg.__PhysicsMaterialsInfo_path);
        _infos = JsonConvert.DeserializeObject<PhysicsMaterialsInfo>(jsonText);
        foreach (var object_kv in _infos.items){
            load_item(object_kv.Key);
        }
    }
}
