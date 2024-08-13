import React, { useState, useEffect, Fragment } from "react";
import { Card, Dropdown, Loader, Dimmer } from "semantic-ui-react";
import _ from "lodash";
import moment from "moment";

import "semantic-ui-css/semantic.min.css";
import "../Styles/default";

import MessageBox from "../Shared/MessageBox";
import axios from "axios";

export default function StatusChart({ project, month_range, states }) {
  const [dataset, setDataset] = useState(null);
  const [chartReady, setChartReady] = useState(true);
  const [label, setLabel] = useState(null);
  const [loading, setLoading] = useState(true);
  const [stateId, setStateId] = useState("all");
  const [month, setMonth] = useState("all");
  const [message, setMessage] = useState(null);

  // console.log("StatusChart", { project, month_range, stateId, month, dataset });

  useEffect(() => {
    fetch();
  }, [stateId, month]);

  useEffect(() => {
    if (dataset) {
      setChartReady(true);
    } else {
      setChartReady(false);
    }
  }, [dataset]);

  useEffect(() => {
    if (!chartReady) return null;
    var render_dataset = [];

    for (var key in dataset) {
      var obj = {
        label: key,
        data: dataset[key].data,
        backgroundColor: dataset[key].background,
        borderColor: "$white",
      };
      render_dataset.push(obj);
    }

    var ctx = document
      .getElementById(`status_chart_${project}`)
      .getContext("2d");
    ctx.height = 500;
    new Chart(ctx, {
      type: "bar",
      data: {
        labels: label,
        datasets: render_dataset,
      },
      options: {
        base: 0,
        maintainAspectRatio: false,
        scales: {
          yAxes: [
            {
              ticks: {
                beginAtZero: true,
              },
            },
          ],
        },
      },
    });
  }, [chartReady]);

  const handleChange = (i, { name, value }) => {
    if (name === "state_id") {
      setStateId(value);
    } else {
      setMonth(value === "all" ? "all" : month_range[value]);
    }
  };

  const fetch = () => {
    setDataset(null);
    setMessage(null);

    const obj = {
      project: project,
      state_id: stateId,
      month: month,
    };

    if (month != "all") {
      obj.month = month.month;
      obj.year = month.year;
    }
    setLoading(true);

    setTimeout(() => {
      axios
        .get(`/production_status_data.json`, { params: obj })
        .then((response) => {
          if (response.data.status) {
            setLabel(response.data.label);
            setDataset(response.data.datasets);
          } else {
            setMessage(response.data.message);
            setDataset(null);
          }
          setLoading(false);
        })
        .catch((err) => {
          setMessage("Something went wrong");
        });
    }, 500);
  };

  return (
    <Card className="ui fluid card">
      <Card.Content>
        <Card.Header>
          {project} Production Status Tracking for{" "}
          <Dropdown
            name="state_id"
            className="status_chart_dropdown"
            inline
            onChange={handleChange}
            options={[
              {
                key: "all",
                text: "All States",
                value: "all",
              },
            ].concat(
              states.map((state) => {
                return {
                  key: state.id,
                  text: state.name,
                  value: state.id,
                };
              })
            )}
            defaultValue={"all"}
          />{" "}
          and{" "}
          <Dropdown
            name="month"
            className="status_chart_dropdown"
            inline
            onChange={handleChange}
            options={[
              {
                key: "all",
                text: "Project Year",
                value: "all",
              },
            ].concat(
              month_range.map((month, index) => {
                return {
                  key: index,
                  text: month.label,
                  value: index,
                };
              })
            )}
            defaultValue={"all"}
          />
        </Card.Header>
      </Card.Content>
      <Card.Content>
        {message && <MessageBox message={message} />}
        {loading && <MessageBox status="Loading" message={"Fetching Counts"} />}
        {chartReady && (
          <div
            style={{
              height: "400px",
              display: dataset ? "block" : "none",
            }}
          >
            <canvas id={`status_chart_${project}`} />
          </div>
        )}
      </Card.Content>
    </Card>
  );
}
