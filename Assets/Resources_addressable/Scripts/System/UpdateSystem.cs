using System.Collections.Generic;
using System.Linq;
using UnityEngine;

public delegate void UpdateAction();
public class Updater {
    BaseClass Base;
    float elapsed_time;

    public Updater(BaseClass baseClass){
        Base = baseClass;
        elapsed_time = 0;
    }
    public void _run(float delta_time){
        // interval == 0, run action every frame
        if (Base._update_interval == 0) {
            Base._update();
            return;
        }
        // interval > 0, run action every interval
        elapsed_time += delta_time;
        if (elapsed_time >= Base._update_interval) {
            Base._update();
            elapsed_time -= Base._update_interval;
        }
    }
}

public class UpdateSystem: BaseClass{
    Dictionary<int, Updater> runtimeID2updater = new();

    public void Update(){
        List<int> keys = runtimeID2updater.Keys.ToList();
        foreach (int key in keys){
            if (!runtimeID2updater.ContainsKey(key)) continue;
            Updater updater = runtimeID2updater[key];
            updater._run(Time.deltaTime);
        }
    }

    public void _add_updater(BaseClass baseClass){
        runtimeID2updater.Add(baseClass._runtimeID, new(baseClass));
    }

    public void _remove_updater(BaseClass baseClass){
        runtimeID2updater.Remove(baseClass._runtimeID);
    }
}
