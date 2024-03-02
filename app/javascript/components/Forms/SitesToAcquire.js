import React, { useState, useEffect, Fragment } from "react";
import {
  Button,
  Grid,
  Header,
  Label,
  Icon,
  Divider,
  Checkbox,
  Breadcrumb,
  Table,
  Tab,
} from "semantic-ui-react";
import _ from "lodash";

import "semantic-ui-css/semantic.min.css";

import Breadcrumbs from "../Shared/Breadcrumb";
import { Controller, useForm } from "react-hook-form";
import MessageBox from "../Shared/MessageBox";
import moment from "moment";
import axios from "axios";
import { DateInput } from "semantic-ui-calendar-react";
import { tableSortReducer } from "../Shared/TableSort";

export default function SitesToAcquire({ sl, naip, token }) {
  const [message, setMessage] = useState(null);
  const [accordionState, setAccordionState] = useState(false);
  const [results, setResults] = useState(null);
  const [project, setProject] = useState("SL");

  console.log("SitesToAcquire", {
    sl,
    naip,
    project,
  });

  const onExport = (data) => {
    console.error("onExport", data);

    // window.open(
    //   `/imagery_upload_status/download?${new URLSearchParams({
    //     project: data.project,
    //     date_from: moment(data.date_from, "l").format("YYYY-MM-DD"),
    //     date_to: moment(data.date_to, "l").format("YYYY-MM-DD"),
    //   }).toString()}`,
    //   "_blank"
    // );
  };

  return (
    <div>
      <Breadcrumbs>
        <Breadcrumb.Section>Reports</Breadcrumb.Section>
        <Breadcrumb.Divider />
        <Breadcrumb.Section active>Left to Fly</Breadcrumb.Section>
      </Breadcrumbs>
      <Divider />
      {/* {renderHelp()} */}
      {/* <Divider /> */}
      <Tab
        menu={{ secondary: true, pointing: true }}
        panes={[
          {
            menuItem: "SL",
            render: () => <RenderSL records={sl} token={token} />,
          },
          // {
          //   menuItem: "NAIP",
          //   render: () => <RenderNaip records={naip} token={token} />,
          // },
        ]}
      />
      <br />
      <br />
    </div>
  );

  function RenderSL({ records, token }) {
    const [states, setStates] = useState([]);
    const [message, setMessage] = useState(null);

    console.log("RenderSL", { records, states });

    const [state, dispatch] = React.useReducer(tableSortReducer, {
      column: null,
      data: records,
      direction: null,
    });
    const { column, data, direction } = state;

    const checkAll = () => {
      var ids = records
        .filter((record) => record.not_flown > 0)
        .map((record) => record.id);
      setStates(ids);
    };
    const unCheckAll = () => {
      setStates([]);
    };

    const handleChange = (e, { checked, value }) => {
      console.log("handleChange", { checked, value });

      var records = [...states];

      if (checked) {
        if (records.indexOf(value) === -1) {
          records.push(value);
        }
      } else {
        var index = records.indexOf(value);
        if (index !== -1) {
          records.splice(index, 1);
        }
      }
      setStates(records);
    };

    const onSubmit = (data) => {
      console.error("onSubmit", data);

      if (states.length === 0) {
        setMessage({
          status: "Error",
          text: "Select one or more states to export shapefile",
        });
      }

      setMessage(null);

      // Build the shapefile
      axios
        .post(`/easements_to_fly/generate`, {
          authenticity_token: token,
          project: "SL",
          states: states,
        })
        .then(({ data }) => {
          console.log("submit response", data);

          if (data.state) {
            window.open(
              `/easements_to_fly/download/${data.history_id}`,
              "_blank"
            );
          } else {
            setMessage({
              status: "Error",
              text: data.message,
            });
          }
        })
        .catch((err) => {
          console.log(err);
          setMessage({
            status: "Error",
            text: "Something went wrong",
          });
          window.onbeforeunload = null;
        });

      // window.open(
      //   `/imagery_upload_status/download?${new URLSearchParams({
      //     project: "SL",
      //     date_from: moment(data.date_from, "l").format("YYYY-MM-DD"),
      //     date_to: moment(data.date_to, "l").format("YYYY-MM-DD"),
      //   }).toString()}`,
      //   "_blank"
      // );
    };

    if (data.length === 0) {
      return (
        <MessageBox title={"No Records Found"} message={"An Error Occurred"} />
      );
    }

    return (
      <Fragment>
        {message && (
          <MessageBox status={message.status} message={message.text} />
        )}
        <Table sortable celled textAlign="center">
          <Table.Header>
            <Table.Row>
              <Table.HeaderCell />
              <Table.HeaderCell
                sorted={column === "name" ? direction : null}
                onClick={() =>
                  dispatch({ type: "CHANGE_SORT", column: "name" })
                }
              >
                State
              </Table.HeaderCell>
              <Table.HeaderCell
                sorted={column === "total" ? direction : null}
                onClick={() =>
                  dispatch({ type: "CHANGE_SORT", column: "total" })
                }
              >
                Total Easements
              </Table.HeaderCell>
              <Table.HeaderCell
                sorted={column === "not_flown" ? direction : null}
                onClick={() =>
                  dispatch({ type: "CHANGE_SORT", column: "not_flown" })
                }
              >
                Easements to Fly
              </Table.HeaderCell>
              <Table.HeaderCell
                sorted={column === "remaining_acres" ? direction : null}
                onClick={() =>
                  dispatch({ type: "CHANGE_SORT", column: "remaining_acres" })
                }
              >
                Remaining Acres
              </Table.HeaderCell>
              <Table.HeaderCell
                sorted={column === "percentage_flown" ? direction : null}
                onClick={() =>
                  dispatch({ type: "CHANGE_SORT", column: "percentage_flown" })
                }
              >
                % Flown
              </Table.HeaderCell>
              <Table.HeaderCell
                sorted={column === "percentage_remaining" ? direction : null}
                onClick={() =>
                  dispatch({
                    type: "CHANGE_SORT",
                    column: "percentage_remaining",
                  })
                }
              >
                % Remaining
              </Table.HeaderCell>
            </Table.Row>
          </Table.Header>

          <Table.Body>
            {data.map((record, index) => {
              return (
                <Table.Row key={index}>
                  <Table.Cell collapsing>
                    {record.not_flown > 0 && (
                      <Checkbox
                        value={record.id}
                        checked={states.includes(record.id)}
                        onChange={handleChange}
                      />
                    )}
                  </Table.Cell>
                  <Table.Cell>{record.name}</Table.Cell>
                  <Table.Cell>{record.total}</Table.Cell>
                  <Table.Cell>{record.not_flown}</Table.Cell>
                  <Table.Cell>{record.remaining_acres}</Table.Cell>
                  <Table.Cell>{record.percentage_flown}%</Table.Cell>
                  <Table.Cell>{record.percentage_remaining}%</Table.Cell>
                </Table.Row>
              );
            })}
          </Table.Body>
        </Table>
        <Divider />
        <Button.Group>
          <Button onClick={checkAll}>
            <Icon name="check square outline" />
            Check All
          </Button>
          <Button onClick={unCheckAll}>
            <Icon name="square outline" />
            UnCheck All
          </Button>
        </Button.Group>
        <Button primary floated="right" type="button" onClick={onSubmit}>
          Download Selected States
        </Button>
        <br />
        <br />
      </Fragment>
    );
  }


  function RenderNaip({ records, token }) {
    const [states, setStates] = useState([]);
    const [message, setMessage] = useState(null);

    console.log("RenderNaip", { records, states });

    const [state, dispatch] = React.useReducer(tableSortReducer, {
      column: null,
      data: records,
      direction: null,
    });
    const { column, data, direction } = state;

    const checkAll = () => {
      var ids = records
        .filter((record) => record.not_flown > 0)
        .map((record) => record.id);
      setStates(ids);
    };
    const unCheckAll = () => {
      setStates([]);
    };

    const handleChange = (e, { checked, value }) => {
      console.log("handleChange", { checked, value });

      var records = [...states];

      if (checked) {
        if (records.indexOf(value) === -1) {
          records.push(value);
        }
      } else {
        var index = records.indexOf(value);
        if (index !== -1) {
          records.splice(index, 1);
        }
      }
      setStates(records);
    };

    const onSubmit = (data) => {
      console.error("onSubmit", data);

      if (states.length === 0) {
        setMessage({
          status: "Error",
          text: "Select one or more states to export shapefile",
        });
      }

      setMessage(null);

      // Build the shapefile
      axios
        .post(`/easements_to_fly/generate`, {
          authenticity_token: token,
          project: "NAIP",
          states: states,
        })
        .then(({ data }) => {
          console.log("submit response", data);

          if (data.state) {
            window.open(
              `/easements_to_fly/download/${data.history_id}`,
              "_blank"
            );
          } else {
            setMessage({
              status: "Error",
              text: data.message,
            });
          }
        })
        .catch((err) => {
          console.log(err);
          setMessage({
            status: "Error",
            text: "Something went wrong",
          });
          window.onbeforeunload = null;
        });

      // window.open(
      //   `/imagery_upload_status/download?${new URLSearchParams({
      //     project: "SL",
      //     date_from: moment(data.date_from, "l").format("YYYY-MM-DD"),
      //     date_to: moment(data.date_to, "l").format("YYYY-MM-DD"),
      //   }).toString()}`,
      //   "_blank"
      // );
    };

    if (data.length === 0) {
      return (
        <MessageBox title={"No Records Found"} message={"An Error Occurred"} />
      );
    }

    return (
      <Fragment>
        {message && (
          <MessageBox status={message.status} message={message.text} />
        )}
        <Table sortable celled textAlign="center">
          <Table.Header>
            <Table.Row>
              <Table.HeaderCell />
              <Table.HeaderCell
                sorted={column === "name" ? direction : null}
                onClick={() =>
                  dispatch({ type: "CHANGE_SORT", column: "name" })
                }
              >
                State
              </Table.HeaderCell>
              <Table.HeaderCell
                sorted={column === "total" ? direction : null}
                onClick={() =>
                  dispatch({ type: "CHANGE_SORT", column: "total" })
                }
              >
                Total Easements
              </Table.HeaderCell>
              <Table.HeaderCell
                sorted={column === "not_flown" ? direction : null}
                onClick={() =>
                  dispatch({ type: "CHANGE_SORT", column: "not_flown" })
                }
              >
                Easements to Fly
              </Table.HeaderCell>
              <Table.HeaderCell
                sorted={column === "percentage_flown" ? direction : null}
                onClick={() =>
                  dispatch({ type: "CHANGE_SORT", column: "percentage_flown" })
                }
              >
                % Flown
              </Table.HeaderCell>
              <Table.HeaderCell
                sorted={column === "percentage_remaining" ? direction : null}
                onClick={() =>
                  dispatch({
                    type: "CHANGE_SORT",
                    column: "percentage_remaining",
                  })
                }
              >
                % Remaining
              </Table.HeaderCell>
            </Table.Row>
          </Table.Header>

          <Table.Body>
            {data.map((record, index) => {
              return (
                <Table.Row key={index}>
                  <Table.Cell collapsing>
                    {record.not_flown > 0 && (
                      <Checkbox
                        value={record.id}
                        checked={states.includes(record.id)}
                        onChange={handleChange}
                      />
                    )}
                  </Table.Cell>
                  <Table.Cell>{record.name}</Table.Cell>
                  <Table.Cell>{record.total}</Table.Cell>
                  <Table.Cell>{record.not_flown}</Table.Cell>
                  <Table.Cell>{record.percentage_flown}%</Table.Cell>
                  <Table.Cell>{record.percentage_remaining}%</Table.Cell>
                </Table.Row>
              );
            })}
          </Table.Body>
        </Table>
        <Divider />
        <Button.Group>
          <Button onClick={checkAll}>
            <Icon name="check square outline" />
            Check All
          </Button>
          <Button onClick={unCheckAll}>
            <Icon name="square outline" />
            UnCheck All
          </Button>
        </Button.Group>
        <Button primary floated="right" type="button" onClick={onSubmit}>
          Download Selected States
        </Button>
        <br />
        <br />
      </Fragment>
    );
  }
}
