using UnityEngine;
using UnityEngine.InputSystem;

public class CamController : MonoBehaviour
{
    public Transform target;
    public float orbitSpeed = 100f;
    public float zoomSpeed = 5f;
    public float minZoom = 2f;
    public float maxZoom = 20f;

    private float currentZoom = 10f;
    private float yaw = 0f;
    private float pitch = 20f;
    void Update()
    {
        var keyboard = Keyboard.current;
        var mouse = Mouse.current;

        if (keyboard.aKey.isPressed) yaw -= orbitSpeed * Time.deltaTime;
        if (keyboard.dKey.isPressed) yaw += orbitSpeed * Time.deltaTime;
        if (keyboard.wKey.isPressed) pitch += orbitSpeed * Time.deltaTime;
        if (keyboard.sKey.isPressed) pitch -= orbitSpeed * Time.deltaTime;

        pitch = Mathf.Clamp(pitch, -80f, 80f);
        currentZoom -= mouse.scroll.ReadValue().y * zoomSpeed * Time.deltaTime;
        currentZoom = Mathf.Clamp(currentZoom, minZoom, maxZoom);

        Quaternion rotation = Quaternion.Euler(pitch, yaw, 0f);
        transform.position = target.position - rotation * Vector3.forward * currentZoom;
        transform.LookAt(target);
    }
}
