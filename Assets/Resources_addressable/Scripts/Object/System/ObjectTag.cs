using System.Collections.Generic;
using System.IO;
using Newtonsoft.Json;
using UnityEngine;
using UnityEngine.AddressableAssets;
using UnityEngine.ResourceManagement.AsyncOperations;
using Cysharp.Threading.Tasks;

public struct ObjectTags{
    public List<string> identity;
    public List<string> contact_self;
    public List<string> contact_other;

}

public class ObjectTag{
    GameConfigs _game_configs;
    ObjectsInfo _objects_info;
    public Dictionary<string, GameObject> _name2object = new();
    public Dictionary<string, string> _ID2objectName = new();

    public ObjectTag(GameConfigs game_configs){
        _game_configs = game_configs;
    }
}
