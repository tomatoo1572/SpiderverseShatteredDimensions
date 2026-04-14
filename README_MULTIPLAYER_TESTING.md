# Multiplayer testing prep

This pass adds a real first host/join layer for friend testing.

## What is working in this pass
- Host a world from the Multiplayer menu on your PC.
- Join a host by IP from the Multiplayer menu.
- Tailscale-friendly workflow using the host's Tailscale IP and port 24500.
- Remote player replication:
  - position
  - body yaw / look pitch
  - held item visual
  - skin/body profile
- Chat replication through the host.
- Block place / break replication through the host.
- Host remains the world authority for multiplayer world edits.

## Intended test flow
1. On the host PC, go to Singleplayer and pick the world you want to host.
2. Go to Multiplayer.
3. Enter a player name.
4. Press **Host World**.
5. On the friend PC, go to Multiplayer.
6. Enter a player name.
7. Enter the host's Tailscale IP.
8. Press **Join Server**.

Default port: `24500`

## Good first test checklist
- Can the friend connect?
- Can both players see each other moving?
- Do held items show on the remote player?
- Does chat show on both sides?
- Do placed blocks appear for both players?
- Do broken blocks disappear for both players?

## Current limits of this pass
This is still a first multiplayer pass, not final Minecraft-grade networking yet.

Still local / not fully authoritative yet:
- inventory ownership and full item sync
- item drop pickup authority
- full mob replication
- per-player gamemode rules
- long-term dedicated server export flow

## Tailscale note
For internet friend testing without port forwarding:
- both players install Tailscale
- connect both PCs through Tailscale
- use the host's Tailscale IP in the Join field
