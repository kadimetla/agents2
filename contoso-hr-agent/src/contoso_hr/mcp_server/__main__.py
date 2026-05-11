"""
Contoso HR Agent MCP Server entry point.

Default:  SSE transport on MCP_PORT (8091).
Stdio:    pass --stdio flag — used by MCP Inspector for local dev.

Connect MCP Inspector (stdio):
  npx @modelcontextprotocol/inspector uv run hr-mcp --stdio
"""

from __future__ import annotations
import sys


def main() -> None:
    """Start FastMCP 2 — stdio if --stdio flag present, else SSE on MCP_PORT."""
    stdio_mode = "--stdio" in sys.argv

    if stdio_mode:
        # CRITICAL: stdio mode uses stdout for JSON-RPC. ANY non-JSON write
        # to stdout corrupts the protocol. Two layers of defense:
        #   1. Set env var so CrewAI Crew/Agent verbose=True becomes False
        #      in graph.py + agents.py — CrewAI verbose writes to stdout
        #      via its own Rich console, bypassing logging.basicConfig.
        #   2. Route Python logging + Rich console output to stderr below.
        import os
        os.environ["CONTOSO_HR_MCP_STDIO"] = "1"

    from contoso_hr.config import get_config

    config = get_config()

    if stdio_mode:
        import logging
        from rich.console import Console
        from rich.logging import RichHandler
        stderr_console = Console(stderr=True)
        handler = RichHandler(console=stderr_console, show_time=True, show_path=False, markup=True)
        handler.setFormatter(logging.Formatter("%(message)s"))
        logging.basicConfig(
            level=getattr(logging, config.log_level.upper(), logging.INFO),
            handlers=[handler],
            force=True,
        )

        from contoso_hr.mcp_server.server import mcp
        mcp.run(transport="stdio")
    else:
        from contoso_hr.logging_setup import console, setup_logging
        setup_logging(config.log_level)
        from contoso_hr.mcp_server.server import mcp
        from contoso_hr.util.port_utils import force_kill_port
        port = config.mcp_port
        force_kill_port(port)
        console.print(f"\n[bold cyan]Contoso HR MCP Server[/]")
        console.print(f"  SSE endpoint: [link]http://localhost:{port}/sse[/]")
        console.print(f"  MCP Inspector (stdio): npx @modelcontextprotocol/inspector uv run hr-mcp --stdio\n")
        mcp.run(transport="sse", host="0.0.0.0", port=port)


if __name__ == "__main__":
    main()
