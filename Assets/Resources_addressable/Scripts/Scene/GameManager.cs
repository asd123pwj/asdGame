using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEngine.SceneManagement;

public class GameManager : MonoBehaviour{
    long timeForInhility;
    System.DateTime startTime;

    public void Start() {
        timeForInhility = 5;
    }

    public void PlayGame(){
        SceneManager.LoadScene("MainGame");
    }

    void OnMouseDown(){
        print("down");
    }

    void OnMouseEnter() {
        print("enter");
        startTime = System.DateTime.Now;
    }

    void OnMouseExit(){
        long calmTime = (long)(System.DateTime.Now - startTime).TotalSeconds;
        if (calmTime > timeForInhility){
            print(calmTime);
            SceneManager.LoadScene("Nihility");
        }
    }
}
