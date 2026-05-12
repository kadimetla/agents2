"""Standalone test driver for the `confirm_and_evaluate` MCP elicitation tool.

Why this exists
- MCP Inspector's elicitation handling can be flaky depending on version/transport.
- This script bypasses Inspector entirely: it spawns `uv run hr-mcp --stdio`,
  connects as a raw MCP client, and supplies its own elicitation callback so
  you can exercise all three branches (accept / decline / cancel) without a UI.

Run
    uv run python test_elicitation.py                    # interactive (prompts you)
    uv run python test_elicitation.py --mode accept      # auto-accept (full pipeline ~30-120s)
    uv run python test_elicitation.py --mode decline     # auto-decline (no pipeline)
    uv run python test_elicitation.py --mode cancel      # auto-cancel (no pipeline)
    uv run python test_elicitation.py --mode unchecked   # accept but confirmed=False (proves the inner branch)

What it proves
- The server tool `confirm_and_evaluate` is firing `ctx.elicit()` correctly.
- The elicitation round-trip works end-to-end over stdio JSON-RPC.
- All three protocol outcomes (accept/decline/cancel) are routed correctly
  in `mcp_server/server.py` lines 199-212.
"""

from __future__ import annotations

import argparse
import asyncio
import json
import sys
from typing import Any

from mcp import ClientSession, StdioServerParameters
from mcp.client.stdio import stdio_client
from mcp.shared.context import RequestContext
from mcp.types import (
    ElicitRequestFormParams,
    ElicitRequestURLParams,
    ElicitResult,
)

# Sample resume blob — same kind of content the LangGraph pipeline expects.
SAMPLE_RESUME = """Sarah Chen — Senior Microsoft Certified Trainer (MCT)
Seattle, WA  |  sarah.chen@example.com

CERTIFICATIONS
- MCT (active, 7 years)
- AZ-104 Azure Administrator Associate
- AZ-305 Azure Solutions Architect Expert
- AZ-400 Azure DevOps Engineer Expert
- AI-102 Azure AI Engineer Associate

EXPERIENCE
- Delivered 240+ technical training courses for Microsoft Learning Partners
- 4.8/5.0 average learner CSAT across 6 years
- Curriculum developer for AI-102, AZ-305, AZ-400 (Pluralsight + Pearson)
- Led 18-week cohort programs on enterprise Azure adoption
"""


def make_elicit_callback(mode: str):
    """Return an async elicitation callback that responds based on `mode`.

    The callback signature follows ElicitationFnT in mcp.client.session.
    """

    async def callback(
        context: RequestContext[ClientSession, Any, Any],
        params: ElicitRequestFormParams | ElicitRequestURLParams,
    ) -> ElicitResult:
        # Display what the server is asking
        print("\n" + "=" * 72)
        print("ELICITATION REQUEST RECEIVED FROM SERVER")
        print("=" * 72)
        print(f"Mode: {getattr(params, 'mode', 'unknown')}")
        print(f"\nServer message:\n{params.message}\n")

        # The schema the server wants us to fill (FormParams only)
        if isinstance(params, ElicitRequestFormParams):
            print(f"Requested schema: {json.dumps(params.requestedSchema, indent=2)}")
        print("=" * 72)

        if mode == "interactive":
            return await _interactive_response(params)
        if mode == "accept":
            print(">>> AUTO-RESPONSE: accept (confirmed=True, priority=normal)")
            return ElicitResult(action="accept", content={"confirmed": True, "priority": "normal"})
        if mode == "unchecked":
            print(">>> AUTO-RESPONSE: accept (confirmed=False — should hit declined branch)")
            return ElicitResult(action="accept", content={"confirmed": False, "priority": "normal"})
        if mode == "decline":
            print(">>> AUTO-RESPONSE: decline")
            return ElicitResult(action="decline", content=None)
        if mode == "cancel":
            print(">>> AUTO-RESPONSE: cancel")
            return ElicitResult(action="cancel", content=None)
        raise ValueError(f"Unknown mode: {mode}")

    return callback


async def _interactive_response(params: ElicitRequestFormParams | ElicitRequestURLParams) -> ElicitResult:
    """Prompt the human at the terminal."""
    print("\nYour choice:")
    print("  1 = accept  (confirmed=True, priority=normal)  — runs full pipeline")
    print("  2 = accept  (confirmed=False)                  — short-circuits to 'declined'")
    print("  3 = decline                                    — short-circuits to 'decline'")
    print("  4 = cancel                                     — short-circuits to 'cancel'")
    choice = input("Choice [1-4]: ").strip()
    if choice == "1":
        return ElicitResult(action="accept", content={"confirmed": True, "priority": "normal"})
    if choice == "2":
        return ElicitResult(action="accept", content={"confirmed": False, "priority": "normal"})
    if choice == "3":
        return ElicitResult(action="decline", content=None)
    return ElicitResult(action="cancel", content=None)


async def run(mode: str) -> int:
    """Spawn the MCP server over stdio and call confirm_and_evaluate."""
    server_params = StdioServerParameters(
        command="uv",
        args=["run", "hr-mcp", "--stdio"],
        env=None,
    )

    print(f"Spawning MCP server: {server_params.command} {' '.join(server_params.args)}")
    print(f"Test mode: {mode}\n")

    async with stdio_client(server_params) as (read_stream, write_stream):
        async with ClientSession(
            read_stream,
            write_stream,
            elicitation_callback=make_elicit_callback(mode),
        ) as session:
            init = await session.initialize()
            print(f"Server: {init.serverInfo.name} v{init.serverInfo.version}")
            print(f"Capabilities: {init.capabilities.model_dump(exclude_none=True)}\n")

            # Sanity: confirm the tool is exposed
            tools = await session.list_tools()
            tool_names = [t.name for t in tools.tools]
            print(f"Tools exposed: {tool_names}")
            if "confirm_and_evaluate" not in tool_names:
                print("ERROR: confirm_and_evaluate not found on the server.")
                return 1

            # Fire the tool — this will trigger the elicitation callback above
            print("\nCalling confirm_and_evaluate(...)")
            print("(server will pause and call back into our elicitation handler)\n")

            result = await session.call_tool(
                "confirm_and_evaluate",
                arguments={
                    "resume_text": SAMPLE_RESUME,
                    "filename": "sarah_chen_test.txt",
                },
            )

            print("\n" + "=" * 72)
            print("TOOL RESULT")
            print("=" * 72)
            if result.isError:
                print("Tool returned an error:")
            for block in result.content:
                if hasattr(block, "text"):
                    # Pretty-print JSON if possible
                    try:
                        parsed = json.loads(block.text)
                        print(json.dumps(parsed, indent=2))
                    except (json.JSONDecodeError, TypeError):
                        print(block.text)
                else:
                    print(repr(block))
            print("=" * 72)

    return 0


def main() -> int:
    parser = argparse.ArgumentParser(description="Drive confirm_and_evaluate elicitation end-to-end.")
    parser.add_argument(
        "--mode",
        choices=["interactive", "accept", "decline", "cancel", "unchecked"],
        default="interactive",
        help="How to respond to the elicitation request from the server",
    )
    args = parser.parse_args()
    return asyncio.run(run(args.mode))


if __name__ == "__main__":
    sys.exit(main())
