//edit by KarlVonDonitz
float Extent
<
   string UIName = "Extent";
   string UIWidget = "Slider";
   bool UIVisible =  true;
   float UIMin = 0.00;
   float UIMax = 0.01;
> = float( 0.007 );

float4 ClearColor
<
   string UIName = "ClearColor";
   string UIWidget = "Color";
   bool UIVisible =  true;
> = float4(0,0,0,0);

float Script : STANDARDSGLOBAL <
    string ScriptOutput = "color";
    string ScriptClass = "scene";
    string ScriptOrder = "postprocess";
> = 0.8;

float time :TIME;
float4 MaterialDiffuse : DIFFUSE  < string Object = "Geometry"; >;
static float alpha1 = MaterialDiffuse.a;

float Intensity : CONTROLOBJECT < string name = "(self)"; string item = "Si";>;
float XIntensity : CONTROLOBJECT < string name = "(self)"; string item = "X";>;
float YIntensity : CONTROLOBJECT < string name = "(self)"; string item = "Y";>;
float Flag : CONTROLOBJECT < string name = "(self)"; string item = "Rx";>;
float2 ViewportSize : VIEWPORTPIXELSIZE;

static float2 ViewportOffset = (float2(0.5,0.5)/ViewportSize);

float ClearDepth  = 1.0;


texture2D DepthBuffer : RENDERDEPTHSTENCILTARGET <
    float2 ViewPortRatio = {1.0,1.0};
    string Format = "D24S8";
>;


texture2D ScnMap : RENDERCOLORTARGET <
    float2 ViewPortRatio = {1,1};
    int MipLevels = 1;
    string Format = "A8R8G8B8" ;
>;
sampler2D ScnSamp = sampler_state {
    texture = <ScnMap>;
    MinFilter = LINEAR;
    MagFilter = LINEAR;
    MipFilter = NONE;
    AddressU  = CLAMP;
    AddressV = CLAMP;
};

struct VS_OUTPUT {
    float4 Pos            : POSITION;
    float2 Tex            : TEXCOORD0;
};

VS_OUTPUT VS_passDraw( float4 Pos : POSITION, float2 Tex : TEXCOORD0 ) {
  
	VS_OUTPUT Out = (VS_OUTPUT)0; 
    Out.Pos = Pos;
    Out.Tex = Tex + ViewportOffset;
    return Out;
}

float4 PS_ColorDispalcement( float2 Tex: TEXCOORD0 ) : COLOR {   
    float4 Color=1;
    float2 fTexSize=ViewportSize;
    float2 fmosaicSize= float2(XIntensity*Intensity/10,YIntensity*Intensity/10);
	float2 fintXY=float2(Tex.x*fTexSize.x,Tex.y*fTexSize.y);
	float2 MosicUV=float2(int(fintXY.x/fmosaicSize.x)*fmosaicSize.x,int(fintXY.y/fmosaicSize.y)*fmosaicSize.y);
	float2 UVMosaic=float2(MosicUV.x/fTexSize.x,MosicUV.y/fTexSize.y);
    float2 fXYmosaic = float2(int(fintXY.x/fmosaicSize.x)*fmosaicSize.x,int(fintXY.y/fmosaicSize.y)*fmosaicSize.y)+0.5*fmosaicSize;
    float2 fDelXY=fXYmosaic-fintXY;
    float2 fUVmosaic=float2(fXYmosaic.x/fTexSize.x,fXYmosaic.y/fTexSize.y);
    if ( Flag) {
	if( length(fDelXY) <0.5*fmosaicSize.x)
     return tex2D(ScnSamp,fUVmosaic);
    else return float4(0,0,0,0);	 
	} else{
	return tex2D(ScnSamp,UVMosaic);
	}
}

technique ColorShift <
    string Script = 
        
        "RenderColorTarget0=ScnMap;"
        "RenderDepthStencilTarget=DepthBuffer;"
        "ClearSetColor=ClearColor;"
        "ClearSetDepth=ClearDepth;"
        "Clear=Color;"
        "Clear=Depth;"
        "ScriptExternal=Color;"
        
        "RenderColorTarget0=;"
        "RenderDepthStencilTarget=;"
        "ClearSetColor=ClearColor;"
        "ClearSetDepth=ClearDepth;"
        "Clear=Color;"
        "Clear=Depth;"
        "Pass=ColorShiftPass;"
    ;
    
> {
    pass ColorShiftPass < string Script= "Draw=Buffer;"; > {
        AlphaBlendEnable = FALSE;
        VertexShader = compile vs_3_0 VS_passDraw();
        PixelShader  = compile ps_3_0 PS_ColorDispalcement();
    }
}
