import React, { useState, useEffect, Fragment } from "react";
import { Card, Dropdown, Loader, Dimmer } from "semantic-ui-react";
import _ from "lodash";
import moment from "moment";

import "semantic-ui-css/semantic.min.css";
import "../Styles/default";

import MessageBox from "../Shared/MessageBox";
import axios from "axios";

const MileStones = ({ project }) => {
  const [dataset, setDataset] = useState(null);
  const [chartReady, setChartReady] = useState(false);
  const [label, setLabel] = useState(null);
  const [loading, setLoading] = useState(true);
  const [message, setMessage] = useState(null);

  // console.log("MileStones", {
  //   dataset,
  //   chartReady,
  //   label,
  //   loading,
  //   message,
  // });

  useEffect(() => {
    fetch();
  }, []);

  useEffect(() => {
    if (!chartReady) return null;
    var render_dataset = [];

    // console.error({ dataset });

    let labelArr = [];
    let dataArr = [];
    let colorArr = [];

    for (var key in dataset) {
      // console.error(dataset[key].data);

      labelArr.push(key);
      dataArr.push(dataset[key].data.toFixed(3));
      // dataArr.push({
      //   label: key,
      //   data: [dataset[key].data.toFixed(3)],
      //   backgroundColor: dataset[key].background,
      // });
      colorArr.push(dataset[key].background);
    }

    // console.log({
    //   labelArr,
    //   dataArr,
    //   colorArr,
    // });

    var ctx = document.getElementById(`milestones_${project}`).getContext("2d");
    ctx.height = 500;
    new Chart(ctx, {
      type: "horizontalBar",
      data: {
        labels: labelArr,
        // datasets: dataArr
        datasets: [
          {
            data: dataArr,
            backgroundColor: colorArr,
          },
        ],

        // labels: ["Label 1", "Label 2", "Label 3", "Label 4", "Label 5", "Label 6", "Label 7"],
        // datasets: [{
        //   data: [2000, 4000, 6000, 8000, 10000, 12000, 14000],
        //   backgroundColor: ["#73BFB8", "#73BFB8", "#73BFB8", "#73BFB8", "#73BFB8", "#73BFB8", "#73BFB8"],
        // }]
      },
      options: {
        legend: {
          display: false,
          position: "bottom",
          fullWidth: true,
          labels: {
            boxWidth: 10,
            padding: 50,
          },
        },
        base: 0,
        maintainAspectRatio: false,
        scales: {
          xAxes: [
            {
              ticks: {
                beginAtZero: true,
                min: 0,
                max: 100,

                callback: function (value) {
                  return value + '%'; // convert it to percentage
                },
              },
            },
          ],
        },
      },
    });
  }, [chartReady]);

  useEffect(() => {
    if (dataset) {
      setChartReady(true);
    } else {
      setChartReady(false);
    }
  }, [dataset]);

  const fetch = () => {
    setDataset(null);
    setMessage(null);

    const obj = {
      project: project,
    };

    setLoading(true);

    setTimeout(() => {
      axios
        .get(`/milestones.json`, { params: obj })
        .then((response) => {
          // console.error({ response });
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
        <Card.Header>{project} Milestones</Card.Header>
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
            <canvas id={`milestones_${project}`} />
          </div>
        )}
      </Card.Content>
    </Card>
  );
};

export default MileStones;
