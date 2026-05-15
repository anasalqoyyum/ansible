return {
  "emrearmagan/atlas.nvim",
  keys = {
    { "<leader>gq", "<cmd>AtlasPulls bitbucket<cr>", desc = "Atlas Pull Requests" },
  },
  config = function()
    require("atlas").setup({
      diff = {
        open_cmd = "DiffviewOpen",
      },
      repo_config = {
        paths = {},
      },
      pulls = {
        providers = {
          bitbucket = {
            user = os.getenv("BKT_USER") or "",
            token = os.getenv("BKT_TOKEN") or "",
            cache_ttl = 300,

            ---@type AtlasBitbucketViewConfig[]
            views = {
              {
                name = "Me",
                key = "M",
                layout = "compact",
                repos = {},

                ---@param pr PullRequest
                ---@param ctx { user: PullsUser|nil }
                filter = function(pr, ctx)
                  local user = ctx.user
                  return pr.author and user and pr.author.id == user.id
                end,
              },
              {
                name = "Team",
                key = "1",
                layout = "plain", -- "compact" or "plain"
                repos = {},
              },
            },
          },
          github = {},
        },
      },
      issues = {
        providers = {
          jira = {},
          github = {},
        },
      },
    })
  end,
}
