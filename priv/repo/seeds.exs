# Script for populating the database. You can run it as:
#
#     mix run priv/repo/seeds.exs
#
# Inside the script, you can read and write to any of your
# repositories directly:
#
#     Scout.Repo.insert!(%Scout.SomeSchema{})
#
# We recommend using the bang functions (`insert!`, `update!`
# and so on) as they will fail if something goes wrong.

alias Scout.Repo

survey_owner_id = Ecto.UUID.bingenerate()
now = DateTime.utc_now()

{2, [%{id: signup_survey_id}, %{id: donation_survey_id}]} =
  Repo.insert_all(
    "surveys",
    [
      %{
        owner_id: survey_owner_id,
        name: "Awesome event signup survey",
        state: "design",
        inserted_at: now,
        updated_at: now
      },
      %{
        owner_id: survey_owner_id,
        name: "Awesome event donation survey",
        state: "design",
        inserted_at: now,
        updated_at: now
      },
    ],
    returning: [:id])

Repo.insert_all(
  "questions",
  [
    %{
      survey_id: signup_survey_id,
      display_index: 1,
      question: "T-Shirt size",
      answer_format: "select",
      options: ["S", "M", "L", "XL"],
      inserted_at: now,
      updated_at: now
    },
    %{
      survey_id: donation_survey_id,
      display_index: 1,
      question: "How would you like your funds to be allocated?",
      answer_format: "radio",
      options: ["Cancer ward", "Maternaty ward", "Psychiatric ward"],
      inserted_at: now,
      updated_at: now
    }
  ])

  Repo.insert_all(
    "responses",
    [
      %{
        survey_id: donation_survey_id,
        respondant_email: "Reece.Pondant@gmail.com",
        answers: ["Cancer ward"],
        inserted_at: now,
        updated_at: now
      }
    ])
