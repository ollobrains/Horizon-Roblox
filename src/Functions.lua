--[[
	@module UtilityFunctions
	@description A set of miscellaneous functions for spawning, welding, randomization, 
	             and other general tasks in Roblox. Part of the "Blood-Engine."

	Author: <Your Name or Team>
	Last updated: YYYY-MM-DD
]]

local TweenService = game:GetService("TweenService")
local Workspace = game:GetService("Workspace")

--// Module Declaration
local UtilityFunctions = {}

--// Internal references
local ParentClass = script.Parent
local Assets = ParentClass:WaitForChild("Assets") -- safer than `.Assets`, ensures existence

--// Asset references
local Images = Assets:WaitForChild("Images")
local Essentials = Assets:WaitForChild("Essentials")
local Effects = Assets:WaitForChild("Effects")

local TrailEffects = Effects:WaitForChild("Trail")
local ImpactEffects = Effects:WaitForChild("Impact")

local FastCast = require(Essentials:WaitForChild("FastCast"))

--// Global objects
local RandomGen = Random.new()
local Decals = Images:GetChildren()

--// Table of property names for droplet reset
local ResettableProperties = {
	"Size",
	"Transparency",
	"Anchored",
}

--[[
	@function IsOfType
	@within UtilityFunctions
	@desc Shortcut for checking if `Any` matches `Type`.
	@param Any any
	@param Type string
	@return boolean
]]
function UtilityFunctions.IsOfType(Any, Type)
	return typeof(Any) == Type
end

--[[
	@function MultiInsert
	@within UtilityFunctions
	@desc Inserts an array of `Variables` onto a table `List` in an efficient manner. 
	      If the variable is a function, it is called first and expected to return the real value to insert.
	@param List table
	@param Variables table
]]
function UtilityFunctions.MultiInsert(List, Variables)
	for Key, Variable in pairs(Variables) do
		if UtilityFunctions.IsOfType(Variable, "function") then
			Variable = Variable()
		end

		if UtilityFunctions.IsOfType(Key, "string") then
			List[Key] = Variable
		else
			table.insert(List, Variable)
		end
	end
end

--[[
	@function GetFunctionName
	@within UtilityFunctions
	@desc Returns the key name of the specified `Function` within `Table`.
	@param Function function
	@param Table table
	@return string|nil
]]
function UtilityFunctions.GetFunctionName(Function, Table)
	for Name, AltFunction in pairs(Table) do
		if AltFunction == Function then
			return Name
		end
	end

	return nil
end

--[[
	@function SetupBehavior
	@within UtilityFunctions
	@desc Sets up and returns a FastCast behavior object.
	@param Cache any - A cosmetic bullet provider or item cache
	@param CastParams RaycastParams
	@return FastCast.Behavior
]]
function UtilityFunctions.SetupBehavior(Cache, CastParams)
	local Behavior = FastCast.newBehavior()
	local Gravity = Workspace.Gravity

	Behavior.Acceleration = Vector3.new(0, -Gravity, 0)
	Behavior.MaxDistance = 500
	Behavior.RaycastParams = CastParams
	Behavior.CosmeticBulletProvider = Cache

	return Behavior
end

--[[
	@function CreateEffects
	@within UtilityFunctions
	@desc Clones and attaches droplet/trail/impact effects to a given mesh part.
	@param Parent MeshPart
	@param ImpactName string - Name for the impact attachment
]]
function UtilityFunctions.CreateEffects(Parent, ImpactName)
	local TrailClone = TrailEffects:Clone()

	local Attachment0 = Instance.new("Attachment")
	local Attachment1 = Instance.new("Attachment")
	local ImpactAttachment = Instance.new("Attachment")

	TrailClone.Attachment0 = Attachment0
	TrailClone.Attachment1 = Attachment1

	Attachment0.Name = "Attachment0"
	Attachment1.Name = "Attachment1"
	Attachment1.Position = Vector3.new(0.037, 0, 0) -- small offset

	Attachment0.Parent = Parent
	Attachment1.Parent = Parent
	TrailClone.Parent = Parent

	for _, Effect in ipairs(ImpactEffects:GetChildren()) do
		local Clone = Effect:Clone()
		Clone.Parent = ImpactAttachment
	end

	ImpactAttachment.Name = ImpactName
	ImpactAttachment.Orientation = Vector3.new(0, 0, 0)
	ImpactAttachment.Parent = Parent
end

--[[
	@function GetDroplet
	@within UtilityFunctions
	@desc Returns a small mesh part configured as a droplet. 
	      Also creates default trail/impact attachments via `CreateEffects`.
	@param ImpactName string
	@param IsDecal boolean
	@return MeshPart
]]
function UtilityFunctions.GetDroplet(ImpactName, IsDecal)
	local Droplet = Instance.new("MeshPart")

	Droplet.Size = Vector3.new(0.1, 0.1, 0.1)
	Droplet.Transparency = 0.25
	Droplet.Material = Enum.Material.Glass
	Droplet.Anchored = false
	Droplet.CanCollide = false
	Droplet.CanQuery = false
	Droplet.CanTouch = false

	UtilityFunctions.CreateEffects(Droplet, ImpactName)
	return Droplet
end

--[[
	@function GetFolder
	@within UtilityFunctions
	@desc Returns a folder named `Name` under `Workspace.Terrain`. Creates it if missing.
	@param Name string
	@return Folder
]]
function UtilityFunctions.GetFolder(Name)
	local Terrain = Workspace.Terrain
	local ExistingFolder = Terrain:FindFirstChild(Name)
	if ExistingFolder then
		return ExistingFolder
	end

	local NewFolder = Instance.new("Folder")
	NewFolder.Name = Name
	NewFolder.Parent = Terrain
	return NewFolder
end

--[[
	@function GetVector
	@within UtilityFunctions
	@desc Creates a random Vector3 from the array Range. 
	      Calls Random:NextNumber on each axis with the same min/max.
	@param Range table [Min, Max]
	@return Vector3
]]
function UtilityFunctions.GetVector(Range)
	local x = RandomGen:NextNumber(unpack(Range))
	local y = RandomGen:NextNumber(unpack(Range))
	local z = RandomGen:NextNumber(unpack(Range))
	return Vector3.new(x, y, z)
end

--[[
	@function NextNumber
	@within UtilityFunctions
	@desc Returns a random float in [Minimum, Maximum].
	@param Minimum number
	@param Maximum number
	@return number
]]
function UtilityFunctions.NextNumber(Minimum, Maximum)
	return RandomGen:NextNumber(Minimum, Maximum)
end

--[[
	@function CreateTween
	@within UtilityFunctions
	@desc Shortcut to quickly create a tween.
	@param Object Instance
	@param Info TweenInfo
	@param Goal table
	@return Tween
]]
function UtilityFunctions.CreateTween(Object, Info, Goal)
	return TweenService:Create(Object, Info, Goal)
end

--[[
	@function PlaySound
	@within UtilityFunctions
	@desc Clones and plays a `Sound` inside `Parent`. Once finished, it is destroyed.
	@param Sound Sound
	@param Parent Instance
]]
function UtilityFunctions.PlaySound(Sound, Parent)
	if not Sound then
		return
	end

	local SoundClone = Sound:Clone()
	SoundClone.Parent = Parent

	SoundClone.Ended:Connect(function()
		SoundClone:Destroy()
	end)

	SoundClone:Play()
end

--[[
	@function GetRandom
	@within UtilityFunctions
	@desc Returns a random element from the given Table, or nil if empty.
	@param Table table
	@return any|nil
]]
function UtilityFunctions.GetRandom(Table)
	local Count = #Table
	if Count == 0 then
		return nil
	end
	return Table[math.random(1, Count)]
end

--[[
	@function ResetDroplet
	@within UtilityFunctions
	@desc Resets the properties of the droplet `Object` using the original reference.
	      Typically used in object pooling.
	@param Object Instance - The droplet object to reset
	@param Original Instance - The reference containing original property values
	@return Instance
]]
function UtilityFunctions.ResetDroplet(Object, Original)
	local decal = Object:FindFirstChildOfClass("SurfaceAppearance")
	local weld = Object:FindFirstChildOfClass("WeldConstraint")
	local trail = Object:FindFirstChildOfClass("Trail")

	for _, Property in ipairs(ResettableProperties) do
		Object[Property] = Original[Property]
	end

	if trail then
		trail.Enabled = false
	end

	if weld then
		weld:Destroy()
	end

	if decal then
		decal:Destroy()
	end

	return Object
end

--[[
	@function ApplyDecal
	@within UtilityFunctions
	@desc If IsDecal is true, picks a random Decal from `Decals` and parents it to `Object`.
	@param Object Instance
	@param IsDecal boolean
]]
function UtilityFunctions.ApplyDecal(Object, IsDecal)
	if not IsDecal then
		return
	end

	local RandomDecal = UtilityFunctions.GetRandom(Decals)
	if not RandomDecal then
		warn("ApplyDecal: No Decals found.")
		return
	end

	local DecalClone = RandomDecal:Clone()
	DecalClone.Parent = Object
end

--[[
	@function EmitParticles
	@within UtilityFunctions
	@desc For each ParticleEmitter child of `Attachment`, calls :Emit(Amount).
	@param Attachment Attachment
	@param Amount number
]]
function UtilityFunctions.EmitParticles(Attachment, Amount)
	for _, Child in ipairs(Attachment:GetChildren()) do
		if Child:IsA("ParticleEmitter") then
			Child:Emit(Amount)
		end
	end
end

--[[
	@function GetClosest
	@within UtilityFunctions
	@desc Finds the closest part within `Magnitude` to `Origin`, 
	      ignoring anchored parts and ignoring `Origin` itself.
	@param Origin BasePart
	@param Magnitude number - The search radius
	@param Ancestor Instance - The container from which to search
	@return BasePart|nil
]]
function UtilityFunctions.GetClosest(Origin, Magnitude, Ancestor)
	local ClosestPart = nil
	local MinDist = math.huge

	for _, Child in ipairs(Ancestor:GetChildren()) do
		local Part = Child
		if not Part:IsA("BasePart") then
			continue
		end

		local Dist = (Origin.Position - Part.Position).Magnitude
		local Valid = (not Part.Anchored) and (Part ~= Origin) and (Dist < Magnitude) and (Dist < MinDist)
		if Valid then
			MinDist = Dist
			ClosestPart = Part
		end
	end

	return ClosestPart
end

--[[
	@function GetAngles
	@within UtilityFunctions
	@desc Creates a CFrame of angles, primarily used for orientation
	      of a droplet or decal.
	@param IsDecal boolean
	@param RandomAngles boolean
	@return CFrame
]]
function UtilityFunctions.GetAngles(IsDecal, RandomAngles)
	local RandAngle = UtilityFunctions.NextNumber(0, math.rad(180))
	local AngleX = IsDecal and -math.pi / 2 or math.pi / 2
	local AngleY = RandomAngles and RandAngle or 0
	return CFrame.Angles(AngleX, AngleY, 0)
end

--[[
	@function GetCFrame
	@within UtilityFunctions
	@desc Builds a CFrame from a position plus normal, offset for decals if needed.
	@param Position Vector3
	@param Normal Vector3
	@param IsDecal boolean
	@return CFrame
]]
function UtilityFunctions.GetCFrame(Position, Normal, IsDecal)
	local DecalOffset = IsDecal and (Normal / 76) or Vector3.zero
	local BasePos = Position + DecalOffset
	local Target = Position + Normal
	return CFrame.new(BasePos, Target)
end

--[[
	@function RefineVectors
	@within UtilityFunctions
	@desc If IsDecal is true, zeroes out Y, otherwise returns VectorData as is.
	@param IsDecal boolean
	@param VectorData Vector3
	@return Vector3
]]
function UtilityFunctions.RefineVectors(IsDecal, VectorData)
	local yValue = IsDecal and 0 or VectorData.Y
	return Vector3.new(VectorData.X, yValue, VectorData.Z)
end

--[[
	@function Weld
	@within UtilityFunctions
	@desc Creates a WeldConstraint between Part0 and Part1, sets Part1.Anchored=false.
	@param Part0 BasePart
	@param Part1 BasePart
	@return WeldConstraint
]]
function UtilityFunctions.Weld(Part0, Part1)
	local Weld = Instance.new("WeldConstraint")
	Part1.Anchored = false

	Weld.Part0 = Part0
	Weld.Part1 = Part1
	Weld.Parent = Part1

	return Weld
end

--[[
	@function Connect
	@within UtilityFunctions
	@desc Inserts a new RBXScriptConnection into a given table of connections.
	@param Connection RBXScriptConnection
	@param Holder table
]]
function UtilityFunctions.Connect(Connection, Holder)
	table.insert(Holder, Connection)
end

--[[
	@function DisconnectAll
	@within UtilityFunctions
	@desc Iterates a table of connections, disconnects them, and clears the table entries.
	@param Holder table
]]
function UtilityFunctions.DisconnectAll(Holder)
	for i, Connection in ipairs(Holder) do
		Connection:Disconnect()
		Holder[i] = nil
	end
end

--[[
	@function Replacement
	@within UtilityFunctions
	@desc Placeholder for removed or replaced functions.
]]
function UtilityFunctions.Replacement()
	warn("BLOOD-ENGINE: Attempt to call a deleted function.")
end

return UtilityFunctions
