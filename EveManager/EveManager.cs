﻿using System;
using System.Collections.Generic;
using System.IO;
using System.Linq;
using System.Reflection;
using System.Text;
using UnityEngine;
using Utils;

namespace EVEManager
{
    [KSPAddon(KSPAddon.Startup.EveryScene, false)]
    public class EVEManagerClass : MonoBehaviour, INamed
    {
        protected virtual bool sceneLoad { get { return HighLogic.LoadedScene == GameScenes.MAINMENU || HighLogic.LoadedScene == GameScenes.FLIGHT || HighLogic.LoadedScene == GameScenes.SPACECENTER || HighLogic.LoadedScene == GameScenes.TRACKSTATION; } }
        private static bool useEditor = false;
        public static List<EVEManagerClass> Managers = new List<EVEManagerClass>();
        public static int SCALED_LAYER = 9;
        public static int MACRO_LAYER = 15;
        public static int SCALED_LAYER2 = 10;
        public static int ROTATION_PROPERTY;
        public static int INVROTATION_PROPERTY;
        public static int MAINOFFSET_PROPERTY;
        public static int SHADOWOFFSET_PROPERTY;
        public static int SUNDIR_PROPERTY;

        public String Name { get { return this.GetType().Name; } set { } }

        private void Awake()
        {
            ROTATION_PROPERTY = Shader.PropertyToID("_Rotation");
            INVROTATION_PROPERTY = Shader.PropertyToID("_InvRotation");
            MAINOFFSET_PROPERTY = Shader.PropertyToID("_MainOffset");
            SHADOWOFFSET_PROPERTY = Shader.PropertyToID("_ShadowOffset");
            SUNDIR_PROPERTY = Shader.PropertyToID("_SunDir");
            useEditor = false;
        }

        private void Update()
        {
            if (HighLogic.LoadedScene == GameScenes.FLIGHT || HighLogic.LoadedScene == GameScenes.TRACKSTATION ||
                HighLogic.LoadedScene == GameScenes.MAINMENU || HighLogic.LoadedScene == GameScenes.SPACECENTER)
            {
                bool alt = (Input.GetKey(KeyCode.LeftAlt) || Input.GetKey(KeyCode.RightAlt));
                if (alt && Input.GetKeyDown(KeyCode.E) && sceneLoad)
                {
                    useEditor = !useEditor;
                }
            }
        }
        public static CelestialBody GetCelestialBody(String body)
        {
            CelestialBody[] celestialBodies = CelestialBody.FindObjectsOfType(typeof(CelestialBody)) as CelestialBody[];
            return celestialBodies.Single(n => n.bodyName == body);
        }

        public static Transform GetScaledTransform(string body)
        {
            List<Transform> transforms = ScaledSpace.Instance.scaledSpaceTransforms;
            return transforms.Single(n => n.name == body);
        }

        public static Shader GetShader(Assembly assembly, String resource)
        {
            StreamReader shaderStreamReader = new StreamReader(assembly.GetManifestResourceStream(resource));
            String shaderTxt = shaderStreamReader.ReadToEnd();
            return new Material(shaderTxt).shader;
        }
        private GUISkin _mySkin;
        private Rect _mainWindowRect = new Rect(0, 0, 840, 800);

        protected static int selectedManagerIndex = 0;
        
        private void OnGUI()
        {
            GUI.skin = _mySkin;
            if (useEditor)
            {
                _mainWindowRect.width = 840;
                _mainWindowRect.height = 800;
                _mainWindowRect = GUI.Window(0x8100, _mainWindowRect, DrawMainWindow, "EVE Manager");
            }
        }

        private void DrawMainWindow(int windowID)
        {
            CelestialBody[] celestialBodies = CelestialBody.FindObjectsOfType(typeof(CelestialBody)) as CelestialBody[];
            EVEManagerClass currentManager;

            Rect placement = new Rect(0, 0, 0, 1);
            float width = _mainWindowRect.width - 10;
            float height = _mainWindowRect.height - 10;
            Rect placementBase = new Rect(10, 25, width, height);

            currentManager = GUIHelper.DrawSelector<EVEManagerClass>(Managers, ref selectedManagerIndex, 4, placementBase, ref placement);

            if (currentManager != null)
            {
                currentManager.DrawGUI(placementBase, placement);
            }

            GUI.DragWindow(new Rect(0, 0, 10000, 10000));
        }

        public virtual void DrawGUI(Rect val, Rect val2)
        {
        }

        public static void Log(String message)
        {
            UnityEngine.Debug.Log("EVEManager: " + message);
        }

    }
}
