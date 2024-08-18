using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEngine.SceneManagement;

public class SceneSystem : MonoBehaviour{

    public void Start() {
    }

    public void PlayGame(){
        change_scene("MainGame");
    }

    void change_scene(string scene_name){ SceneManager.LoadScene(scene_name); }

    // void OnMouseDown(){
    //     print("down");
    // }

    // void OnMouseEnter() {
    //     print("enter");
    //     startTime = System.DateTime.Now;
    // }

    // void OnMouseExit(){
    //     long calmTime = (long)(System.DateTime.Now - startTime).TotalSeconds;
    //     if (calmTime > timeForInhility){
    //         print(calmTime);
    //         SceneManager.LoadScene("Nihility");
    //     }
    // }
}
