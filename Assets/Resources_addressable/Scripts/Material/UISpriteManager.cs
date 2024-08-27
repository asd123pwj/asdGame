using System.Collections.Generic;
using System.IO;
using Newtonsoft.Json;
using UnityEngine;
using UnityEngine.AddressableAssets;
using UnityEngine.ResourceManagement.AsyncOperations;
using Cysharp.Threading.Tasks;
using Unity.VectorGraphics;

public struct UISpriteInfo{
    public string name;
    public string path;
}

public struct UISpritesInfo{
    public string version;
    public Dictionary<string, UISpriteInfo> UISprites;
}

public class UISpriteManager: BaseClass{
    // GameConfigs _GCfg;
    public UISpritesInfo _UISprites_info;
    public Dictionary<string, Sprite> _name2UISprite = new();

    public UISpriteManager(){
        // _GCfg = game_configs;
        load_UISprites();
    }

    public bool _check_info_initDone(){
        return !(_UISprites_info.version == null);
    }

    public bool _check_exist(string name){
        return _UISprites_info.UISprites.ContainsKey(name);
    }

    public bool _check_loaded(string name){
        return _name2UISprite.ContainsKey(name);
    }

    public Sprite _get_spr(string name){
        return _name2UISprite[name];
    }

    async UniTaskVoid load_UISprite(string name){
        string UISprite_path = _UISprites_info.UISprites[name].path;
        AsyncOperationHandle<Object> handle = Addressables.LoadAssetAsync<Object>(UISprite_path);
        handle.Completed += action_UISprite_loaded;
        await UniTask.Yield();
    }

    void load_UISprites(){
        string jsonText = File.ReadAllText(_GCfg.__UISpritesInfo_path);
        _UISprites_info = JsonConvert.DeserializeObject<UISpritesInfo>(jsonText);
        foreach (var object_kv in _UISprites_info.UISprites){
            load_UISprite(object_kv.Key).Forget();
        }
    }

    void action_UISprite_loaded(AsyncOperationHandle<Object> handle){
        if (handle.Status == AsyncOperationStatus.Succeeded){
            if (handle.Result is Texture2D texture){
                Sprite sprite = Sprite.Create(texture, new Rect(0, 0, texture.width, texture.height), new Vector2(0.5f, 0.5f));
                _name2UISprite.Add(handle.Result.name, sprite);
            }
            else if (handle.Result is TextAsset textAsset){
                SVGParser.SceneInfo sceneInfo = SVGParser.ImportSVG(new System.IO.StringReader(textAsset.text));
                var tessOptions = new VectorUtils.TessellationOptions(){ StepDistance = 0.1f, MaxCordDeviation = 0.1f, MaxTanAngleDeviation = 0.1f, SamplingStepSize = 0.01f};
                var geometry = VectorUtils.TessellateScene(sceneInfo.Scene, tessOptions);
                Sprite sprite = VectorUtils.BuildSprite(geometry, 1.0f, VectorUtils.Alignment.Center, Vector2.zero, 128, true);
                _name2UISprite.Add(handle.Result.name, sprite);
            }
        }
        else Debug.LogError("Failed to load prefab: " + handle.DebugName);
        Addressables.Release(handle);
    }
}
