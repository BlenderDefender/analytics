defmodule Plausible.FunnelsTest do
  use Plausible.DataCase

  alias Plausible.Goals
  alias Plausible.Funnels
  alias Plausible.Stats

  setup do
    site = insert(:site)

    {:ok, g1} = Goals.create(site, %{"page_path" => "/go/to/blog/**"})
    {:ok, g2} = Goals.create(site, %{"event_name" => "Signup"})
    {:ok, g3} = Goals.create(site, %{"page_path" => "/checkout"})
    {:ok, g4} = Goals.create(site, %{"event_name" => "Leave feedback"})
    {:ok, g5} = Goals.create(site, %{"page_path" => "/recommend"})
    {:ok, g6} = Goals.create(site, %{"event_name" => "Extra event"})

    {:ok,
     %{
       site: site,
       goals: [g1, g2, g3],
       steps: [g1, g2, g3, g4, g5, g6] |> Enum.map(&%{"goal_id" => &1.id})
     }}
  end

  describe "Common context" do
    test "create and store a funnel given a set of goals", %{site: site, steps: [g1, g2, g3 | _]} do
      {:ok, funnel} =
        Funnels.create(
          site,
          "From blog to signup and purchase",
          [g1, g2, g3]
        )

      assert funnel.inserted_at
      assert funnel.name == "From blog to signup and purchase"
      assert [fg1, fg2, fg3] = funnel.steps

      assert fg1.goal_id == g1["goal_id"]
      assert fg2.goal_id == g2["goal_id"]
      assert fg3.goal_id == g3["goal_id"]

      assert fg1.step_order == 1
      assert fg2.step_order == 2
      assert fg3.step_order == 3
    end

    test "retrieve a funnel by id and site, get steps in order", %{
      site: site,
      steps: [g1, g2, g3 | _]
    } do
      {:ok, funnel} =
        Funnels.create(
          site,
          "Lorem ipsum",
          [g3, g1, g2]
        )

      assert funnel = Funnels.get(site, funnel.id)
      assert funnel.name == "Lorem ipsum"
      assert [%{step_order: 1}, %{step_order: 2}, %{step_order: 3}] = funnel.steps
    end

    test "funnels can be deleted by id and a site", %{site: site, steps: [g1, g2 | _]} do
      {:ok, funnel} =
        Funnels.create(
          site,
          "Sample funnel",
          [g1, g2]
        )

      assert :ok = Funnels.delete(site, funnel.id)
      # deletion is idempotent
      assert :ok = Funnels.delete(site, funnel.id)
      refute Funnels.get(site, funnel.id)
    end

    test "a funnel cannot be made of < 2 steps", %{site: site, steps: [g1 | _]} do
      assert {:error, :invalid_funnel_size} =
               Funnels.create(
                 site,
                 "Lorem ipsum",
                 [g1]
               )
    end

    test "a funnel can be made of 5 steps maximum", %{site: site, steps: too_many_steps} do
      assert {:error, :invalid_funnel_size} =
               Funnels.create(
                 site,
                 "Lorem ipsum",
                 too_many_steps
               )
    end

    test "a goal can only appear once in a funnel", %{steps: [g1 | _], site: site} do
      {:error, _changeset} =
        Funnels.create(
          site,
          "Lorem ipsum",
          [g1, g1]
        )
    end

    test "funnels can be listed per site, starting from most recently added", %{
      site: site,
      steps: [g1, g2, g3 | _]
    } do
      Funnels.create(site, "Funnel 1", [g3, g1])
      Funnels.create(site, "Funnel 2", [g2, g1, g3])

      funnels_list = Funnels.list(site)

      assert [%{name: "Funnel 2", steps_count: 3}, %{name: "Funnel 1", steps_count: 2}] =
               funnels_list
    end
  end

  describe "Plausible.Stats.Funnel" do
    test "funnels can be evaluated per site within a time range against an ephemeral definition",
         %{
           site: site,
           goals: [g1, g2, g3 | _]
         } do
      funnel_definition =
        Funnels.ephemeral_definition(
          site,
          "From blog to signup and purchase",
          [
            %{
              "goal_id" => "#{g1.id}",
              "goal" => %{
                "id" => "#{g1.id}",
                "event_name" => g1.event_name,
                "page_path" => g1.page_path
              }
            },
            %{
              "goal_id" => g2.id,
              "goal" => %{
                "id" => g2.id,
                "event_name" => g2.event_name,
                "page_path" => g2.page_path
              }
            },
            %{
              "goal_id" => g3.id,
              "goal" => %{
                "id" => g3.id,
                "event_name" => g3.event_name,
                "page_path" => g3.page_path
              }
            }
          ]
        )

      populate_stats(site, [
        build(:pageview, pathname: "/irrelevant/page/not/in/funnel", user_id: 999),
        build(:pageview, pathname: "/go/to/blog/foo", user_id: 123),
        build(:event, name: "Signup", user_id: 123),
        build(:pageview, pathname: "/checkout", user_id: 123),
        build(:pageview, pathname: "/go/to/blog/bar", user_id: 666),
        build(:event, name: "Signup", user_id: 666)
      ])

      query = Plausible.Stats.Query.from(site, %{"period" => "all"})

      funnel_data = Stats.funnel(site, query, funnel_definition)

      assert {:ok,
              %{
                all_visitors: 3,
                entering_visitors: 2,
                entering_visitors_percentage: "66.67",
                never_entering_visitors: 1,
                never_entering_visitors_percentage: "33.33",
                steps: [
                  %{
                    label: "Visit /go/to/blog/**",
                    visitors: 2,
                    conversion_rate: "100.00",
                    conversion_rate_step: "0.00",
                    dropoff: 0,
                    dropoff_percentage: "0.00"
                  },
                  %{
                    label: "Signup",
                    visitors: 2,
                    conversion_rate: "100.00",
                    conversion_rate_step: "100.00",
                    dropoff: 0,
                    dropoff_percentage: "0.00"
                  },
                  %{
                    label: "Visit /checkout",
                    visitors: 1,
                    conversion_rate: "50.00",
                    conversion_rate_step: "50.00",
                    dropoff: 1,
                    dropoff_percentage: "50.00"
                  }
                ]
              }} = funnel_data
    end

    test "funnels can be evaluated per site within a time range", %{
      site: site,
      steps: [g1, g2, g3 | _]
    } do
      {:ok, funnel} =
        Funnels.create(
          site,
          "From blog to signup and purchase",
          [g1, g2, g3]
        )

      populate_stats(site, [
        build(:pageview, pathname: "/go/to/blog/foo", user_id: 123),
        build(:event, name: "Signup", user_id: 123),
        build(:pageview, pathname: "/checkout", user_id: 123),
        build(:pageview, pathname: "/go/to/blog/bar", user_id: 666),
        build(:event, name: "Signup", user_id: 666)
      ])

      query = Plausible.Stats.Query.from(site, %{"period" => "all"})

      funnel_data = Stats.funnel(site, query, funnel.id)

      assert {:ok,
              %{
                all_visitors: 2,
                entering_visitors: 2,
                entering_visitors_percentage: "100.00",
                never_entering_visitors: 0,
                never_entering_visitors_percentage: "0.00",
                steps: [
                  %{
                    label: "Visit /go/to/blog/**",
                    visitors: 2,
                    conversion_rate: "100.00",
                    conversion_rate_step: "0.00",
                    dropoff: 0
                  },
                  %{
                    label: "Signup",
                    visitors: 2,
                    conversion_rate: "100.00",
                    conversion_rate_step: "100.00",
                    dropoff: 0,
                    dropoff_percentage: "0.00"
                  },
                  %{
                    label: "Visit /checkout",
                    visitors: 1,
                    conversion_rate: "50.00",
                    conversion_rate_step: "50.00",
                    dropoff: 1,
                    dropoff_percentage: "50.00"
                  }
                ]
              }} = funnel_data
    end

    test "funnels can be evaluated even where there are no visits yet", %{
      site: site,
      steps: [g1, g2, g3 | _]
    } do
      {:ok, funnel} =
        Funnels.create(
          site,
          "From blog to signup and purchase",
          [g1, g2, g3]
        )

      query = Plausible.Stats.Query.from(site, %{"period" => "all"})

      funnel_data = Stats.funnel(site, query, funnel.id)

      assert {:ok,
              %{
                all_visitors: 0,
                entering_visitors: 0,
                entering_visitors_percentage: "0.00",
                never_entering_visitors: 0,
                never_entering_visitors_percentage: "0.00",
                steps: [
                  %{
                    label: "Visit /go/to/blog/**",
                    visitors: 0,
                    conversion_rate: "0.00",
                    conversion_rate_step: "0.00",
                    dropoff: 0,
                    dropoff_percentage: "0.00"
                  },
                  %{
                    label: "Signup",
                    visitors: 0,
                    conversion_rate: "0.00",
                    conversion_rate_step: "0.00",
                    dropoff: 0,
                    dropoff_percentage: "0.00"
                  },
                  %{
                    label: "Visit /checkout",
                    visitors: 0,
                    conversion_rate: "0.00",
                    conversion_rate_step: "0.00",
                    dropoff: 0,
                    dropoff_percentage: "0.00"
                  }
                ]
              }} = funnel_data
    end
  end
end
