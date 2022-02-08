local ffi = require "ffi"

ffi.cdef [[
    int VirtualProtect(void* lpAddress, unsigned long dwSize, unsigned long flNewProtect, unsigned long* lpflOldProtect);
    void* VirtualAlloc(void* lpAddress, unsigned long dwSize, unsigned long  flAllocationType, unsigned long flProtect);
    int VirtualFree(void* lpAddress, unsigned long dwSize, unsigned long dwFreeType);

    typedef uintptr_t (__thiscall* GetClientEntity_4242425_t)(void*, int);
	typedef struct 
	{
		float x;
		float y;
		float z;
    } Vector_t;

    typedef struct
  {
      char	pad0[0x60]; // 0x00
      void* pEntity; // 0x60
      void* pActiveWeapon; // 0x64
      void* pLastActiveWeapon; // 0x68
      float		flLastUpdateTime; // 0x6C
      int			iLastUpdateFrame; // 0x70
      float		flLastUpdateIncrement; // 0x74
      float		flEyeYaw; // 0x78
      float		flEyePitch; // 0x7C
      float		flGoalFeetYaw; // 0x80
      float		flLastFeetYaw; // 0x84
      float		flMoveYaw; // 0x88
      float		flLastMoveYaw; // 0x8C // changes when moving/jumping/hitting ground
      float		flLeanAmount; // 0x90
      char	pad1[0x4]; // 0x94
      float		flFeetCycle; // 0x98 0 to 1
      float		flMoveWeight; // 0x9C 0 to 1
      float		flMoveWeightSmoothed; // 0xA0
      float		flDuckAmount; // 0xA4
      float		flHitGroundCycle; // 0xA8
      float		flRecrouchWeight; // 0xAC
      Vector_t		vecOrigin; // 0xB0
      Vector_t		vecLastOrigin;// 0xBC
      Vector_t		vecVelocity; // 0xC8
      Vector_t		vecVelocityNormalized; // 0xD4
      Vector_t		vecVelocityNormalizedNonZero; // 0xE0
      float		flVelocityLenght2D; // 0xEC
      float		flJumpFallVelocity; // 0xF0
      float		flSpeedNormalized; // 0xF4 // clamped velocity from 0 to 1 
      float		flRunningSpeed; // 0xF8
      float		flDuckingSpeed; // 0xFC
      float		flDurationMoving; // 0x100
      float		flDurationStill; // 0x104
      bool		bOnGround; // 0x108
      bool		bHitGroundAnimation; // 0x109
      char	pad2[0x2]; // 0x10A
      float		flNextLowerBodyYawUpdateTime; // 0x10C
      float		flDurationInAir; // 0x110
      float		flLeftGroundHeight; // 0x114
      float		flHitGroundWeight; // 0x118 // from 0 to 1, is 1 when standing
      float		flWalkToRunTransition; // 0x11C // from 0 to 1, doesnt change when walking or crouching, only running
      char	pad3[0x4]; // 0x120
      float		flAffectedFraction; // 0x124 // affected while jumping and running, or when just jumping, 0 to 1
      char	pad4[0x208]; // 0x128
      float		flMinBodyYaw; // 0x330
      float		flMaxBodyYaw; // 0x334
      float		flMinPitch; //0x338
      float		flMaxPitch; // 0x33C
      int			iAnimsetVersion; // 0x340
  } CCSGOPlayerAnimationState_534535_t;

  typedef struct {
    char  pad_0000[20];
    int m_nOrder; //0x0014
    int m_nSequence; //0x0018
    float m_flPrevCycle; //0x001C
    float m_flWeight; //0x0020
    float m_flWeightDeltaRate; //0x0024
    float m_flPlaybackRate; //0x0028
    float m_flCycle; //0x002C
    void *m_pOwner; //0x0030
    char  pad_0038[4]; //0x0034
    } CAnimationLayer_t;
]]

local ENTITY_LIST_POINTER = ffi.cast("void***", Utils.CreateInterface("client.dll", "VClientEntityList003")) or error("Failed to find VClientEntityList003!")
local GET_CLIENT_ENTITY_FN = ffi.cast("GetClientEntity_4242425_t", ENTITY_LIST_POINTER[0][3])

local ffi_helpers = {
    get_entity_address = function(entity_index)
        local addr = GET_CLIENT_ENTITY_FN(ENTITY_LIST_POINTER, entity_index)
        return addr
    end
}

wutman, nulmen = {}, function () end -- :handshake:
function switcher(i)
  return setmetatable({ i }, {
    __call = function (cE, cEE)
      local nomorenaming = #cE == 0 and nulmen or cE[1]
      return (cEE[nomorenaming] or cEE[wutman] or nulmen)(nomorenaming)
    end
  })
end

local static_legs = Menu.SliderFloat("Anims", "Static Legs in Air", 0, 0, 1)
local pitch_land = Menu.Switch("Anims", "0 Pitch on Land", false)
local leg_breaker = Menu.Switch("Anims", "Leg Fucker", false)
local leg_breaker_modes = Menu.Combo("Anims", "LF Modes", {"Static V1", "Static V2", "Jitter 1", "Jitter 2", "Jitter 3", "Jitter 4", "Jitter 5", "Jitter 5 INVERT"}, 0)

local jumping = false


function updateCSA_hk(thisptr, edx)
    local is_localplayer = ffi.cast("uintptr_t", thisptr) == ffi_helpers.get_entity_address(EngineClient.GetLocalPlayer())
    updateCSA_fn(thisptr, edx)
  
    if is_localplayer then
        if pitch_land:Get() and ffi.cast("CCSGOPlayerAnimationState_534535_t**", ffi.cast("uintptr_t", thisptr) + 0x9960)[0].bHitGroundAnimation then
            if not jumping then
                ffi.cast("float*", ffi.cast("uintptr_t", thisptr) + 10104)[12] = 0.5
            end
        end

        ffi.cast("float*", ffi.cast("uintptr_t", thisptr) + 10104)[6] = static_legs:Get()

        if leg_breaker:Get() then
            switcher(leg_breaker_modes:Get()) {
                [0] = function ()
                    ffi.cast("float*", ffi.cast("uintptr_t", thisptr) + 10104)[0] = 1
                end,
                [1] = function ()
                    ffi.cast("float*", ffi.cast("uintptr_t", thisptr) + 10104)[0] = 0
                end,
                [2] = function ()
                    ffi.cast("float*", ffi.cast("uintptr_t", thisptr) + 10104)[0] = GlobalVars.tickcount % 3 == 0 and 0 or 0.1
                end,
                [3] = function ()
                    ffi.cast("float*", ffi.cast("uintptr_t", thisptr) + 10104)[0] = GlobalVars.tickcount % 3 == 0 and 1 or 0.45
                end,
                [4] = function ()
                    ffi.cast("float*", ffi.cast("uintptr_t", thisptr) + 10104)[0] = GlobalVars.tickcount % 3 == 0 and 1 or 0.7
                end,
                [5] = function ()
                    ffi.cast("float*", ffi.cast("uintptr_t", thisptr) + 10104)[0] = GlobalVars.tickcount % 4 == 0 and 1 or 0.9
                end,
                [6] = function ()
                    ffi.cast("float*", ffi.cast("uintptr_t", thisptr) + 10104)[0] = GlobalVars.tickcount % 4 == 0 and 0.5 or 0
                end,
                [7] = function ()
                    ffi.cast("float*", ffi.cast("uintptr_t", thisptr) + 10104)[0] = GlobalVars.tickcount % 4 == 0 and 0 or 0.5
                end
            }
        end
    end
end

local lastlegfucker = 0
Cheat.RegisterCallback("prediction", function(cmd)
    if leg_breaker:Get() then
        local var333 = Menu.FindVar("Aimbot", "Anti Aim", "Misc", "Leg Movement")
        var333:Set(cmd.command_number % 3 == 0 and 0 or 1)
    end
end)

Cheat.RegisterCallback("pre_prediction", function(cmd)
    jumping = bit.band(cmd.buttons, bit.lshift(1,1)) ~= 0
end)

--starthooks() -- have fun remaking this bye
