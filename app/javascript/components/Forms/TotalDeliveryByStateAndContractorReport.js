import React, { useState, useEffect, Fragment } from "react";
import {
  Button,
  Icon,
  Table,
  Accordion,
  Divider,
  Form,
  Breadcrumb,
} from "semantic-ui-react";
import _ from "lodash";
import { Controller, useForm } from "react-hook-form";

import "semantic-ui-css/semantic.min.css";
import "../Styles/default";

import { tableSortReducer } from "../Shared/TableSort";
import Breadcrumbs from "../Shared/Breadcrumb";
import MessageBox from "../Shared/MessageBox";
import axios from "axios";

// function tableSortReducer(state, action) {
//   switch (action.type) {
//     case "CHANGE_SORT":
//       if (state.column === action.column) {
//         return {
//           ...state,
//           data: state.data.slice().reverse(),
//           direction:
//             state.direction === "ascending" ? "descending" : "ascending",
//         };
//       }

//       console.log("tableSortReducer", {
//         column: action.column,
//         data: _.sortBy(state.data, [action.column]),
//         direction: "ascending",
//       });

//       return {
//         column: action.column,
//         data: _.sortBy(state.data, [action.column]),
//         direction: "ascending",
//       };
//     default:
//       throw new Error();
//   }
// }

export default function TotalDeliveryByStateAndContractorReport(props) {
  const [project, setProject] = useState(null);
  const [result, setResult] = useState({});
  const [message, setMessage] = useState(null);
  const [isOpen, setopen] = useState(true);
  const [accordionState, setAccordionState] = useState(true);
  const [loading, setLoading] = useState(false);

  const {
    handleSubmit,
    reset,
    setValue,
    register,
    control,
    formState: { errors },
  } = useForm();

  const handleChange = (e, { name, value }) => {
    setValue(name, value);
  };

  const onSubmit = (data) => {
    console.error(data);

    setLoading(true);
    axios
      .post(`/total_delivery_by_state_and_contractor`, {
        authenticity_token: props.token,
        from_date: data.from_date,
        to_date: data.to_date,
        state_id: data.state,
        company_id: data.company,
        project: data.project,
      })
      .then((response) => {
        console.error("response", { response });
        if (response.data.result) {
          setProject(data.project);
          setResult({})
          setResult(...response.data.result);
        } else {
          setResult({});
          setMessage({
            status: response.data.status || "Error",
            text: response.data.message || "An unexpected error occurred",
          });
        }
        setLoading(false);
      });
  };

  console.log("TotalDeliveryByStateAndContractorReport", props);

  return (
    <div>
      <Breadcrumbs>
        <Breadcrumb.Section>Reports</Breadcrumb.Section>
        <Breadcrumb.Divider />
        <Breadcrumb.Section active>
          Total Delivery by State and Contractor
        </Breadcrumb.Section>
      </Breadcrumbs>
      <Divider />
      <Accordion fluid styled>
        <Accordion.Title
          active={accordionState}
          onClick={() => {
            setAccordionState(!accordionState);
          }}
        >
          <Icon name="dropdown" />
          Query Tool
        </Accordion.Title>
        <Accordion.Content active={accordionState}>
          <Form>
            <Form.Group widths="equal">
              <Controller
                name={"company"}
                control={control}
                rules={{ required: "Required" }}
                render={({ field: { name, value } }) => (
                  <Form.Select
                    fluid
                    search
                    selection
                    clearable
                    name={name}
                    data-value={value}
                    label={"Company"}
                    required={true}
                    value={value}
                    onChange={handleChange}
                    autoComplete="off"
                    options={[{ key: 0, value: "ALL", text: "All" }].concat(
                      props.company.map((record) => {
                        return {
                          key: record.id,
                          value: record.id,
                          text: record.name,
                        };
                      })
                    )}
                    error={
                      errors["company"]
                        ? {
                            content: errors["company"].message,
                            pointing: "above",
                          }
                        : false
                    }
                  />
                )}
              />

              <Controller
                name={"project"}
                control={control}
                rules={{ required: "Required" }}
                render={({ field: { name, value } }) => (
                  <Form.Select
                    fluid
                    search
                    selection
                    clearable
                    name={name}
                    data-value={value}
                    label={"Project"}
                    required={true}
                    value={value}
                    onChange={handleChange}
                    autoComplete="off"
                    options={props.projects.map((record) => {
                      return {
                        key: record,
                        text: record,
                        value: record,
                      };
                    })}
                    error={
                      errors["project"]
                        ? {
                            content: errors["project"].message,
                            pointing: "above",
                          }
                        : false
                    }
                  />
                )}
              />

              <Controller
                name={"state"}
                control={control}
                rules={{ required: "Required" }}
                render={({ field: { name, value } }) => (
                  <Form.Select
                    fluid
                    search
                    selection
                    clearable
                    name={name}
                    data-value={value}
                    label={"State"}
                    required={true}
                    value={value}
                    onChange={handleChange}
                    autoComplete="off"
                    options={[{ key: 0, value: "ALL", text: "All" }].concat(
                      props.states.map((record) => {
                        return {
                          key: record.id,
                          value: record.id,
                          text: record.name,
                        };
                      })
                    )}
                    error={
                      errors["state"]
                        ? {
                            content: errors["state"].message,
                            pointing: "above",
                          }
                        : false
                    }
                  />
                )}
              />

              <Form.Select
                fluid
                label="Months"
                options={[{ key: 0, value: "ALL", text: "All" }].concat(
                  props.months.map((record, index) => {
                    return {
                      key: record.label,
                      value: index,
                      text: record.label,
                    };
                  })
                )}
                onChange={(e, { value }) => {
                  setValue(
                    "from_date",
                    props.months[value === "ALL" ? 0 : value].start_of_month
                  );
                  setValue(
                    "to_date",
                    props.months[
                      value === "ALL" ? props.months.length - 1 : value
                    ].end_of_month
                  );
                }}
              />
            </Form.Group>
            <Form.Group widths="equal">
              <Controller
                name={"from_date"}
                control={control}
                rules={{ required: "Required" }}
                render={({ field: { name, value } }) => (
                  <Form.Select
                    fluid
                    search
                    selection
                    clearable
                    name={name}
                    data-value={value}
                    label={"Ship Month (From)"}
                    required={true}
                    value={value}
                    onChange={handleChange}
                    autoComplete="off"
                    options={props.months.map((record) => {
                      return {
                        key: record.label,
                        value: record.start_of_month,
                        text: record.label,
                      };
                    })}
                    error={
                      errors["from_date"]
                        ? {
                            content: errors["from_date"].message,
                            pointing: "above",
                          }
                        : false
                    }
                  />
                )}
              />
              <Controller
                name={"to_date"}
                control={control}
                rules={{ required: "Required" }}
                render={({ field: { name, value } }) => (
                  <Form.Select
                    fluid
                    search
                    selection
                    clearable
                    name={name}
                    data-value={value}
                    label={"Ship Month (To)"}
                    required={true}
                    value={value}
                    onChange={handleChange}
                    autoComplete="off"
                    options={props.months.map((record) => {
                      return {
                        key: record.label,
                        value: record.end_of_month,
                        text: record.label,
                      };
                    })}
                    error={
                      errors["to_date"]
                        ? {
                            content: errors["to_date"].message,
                            pointing: "above",
                          }
                        : false
                    }
                  />
                )}
              />
            </Form.Group>

            <Divider />
            <Form.Field
              control={Button}
              floated="right"
              primary
              loading={loading}
              disabled={loading}
              onClick={handleSubmit(onSubmit)}
            >
              Submit
            </Form.Field>
            <div style={{ clear: "both" }} />
          </Form>
        </Accordion.Content>
      </Accordion>

      {result &&
        Object.keys(result).map((company, index) => {
          // console.log("iterate", { result, company });
          // if (project === "SL" && project === "NRI") {
            return (
              <RenderNRISLTable
                key={index}
                company={company}
                records={result[company]}
              />
            );
          // } else if (project === "NAIP") {
          //   return (
          //     <RenderNAIPTable
          //       key={index}
          //       company={company}
          //       records={result[company]}
          //     />
          //   );
          // }
        })}

      {message && <MessageBox status={message.status} message={message.text} />}
      <br />
      <br />
    </div>
  );
}

function RenderNRISLTable({ company, records }) {
  const [state, dispatch] = React.useReducer(tableSortReducer, {
    column: null,
    data: records,
    direction: null,
  });
  const { column, data, direction } = state;

  // let nri_count = 0;
  let total_count = 0;
  let total_acres = 0;

  // console.log("TotalDeliveryByStateAndContractorTable", {
  //   company,
  //   records,
  //   data,
  // });

  return (
    <div className="table-overflow">
      <Table
        unstackable
        sortable
        celled
        striped
        key={company}
        textAlign="center"
      >
        <Table.Header>
          <Table.Row textAlign="left">
            <Table.HeaderCell colSpan="5">{company}</Table.HeaderCell>
          </Table.Row>
          <Table.Row>
            <Table.HeaderCell
              sorted={column === "state" ? direction : null}
              onClick={() => dispatch({ type: "CHANGE_SORT", column: "state" })}
            >
              State
            </Table.HeaderCell>
            <Table.HeaderCell
              sorted={column === "month" ? direction : null}
              onClick={() => dispatch({ type: "CHANGE_SORT", column: "month" })}
            >
              Month
            </Table.HeaderCell>
            <Table.HeaderCell
              sorted={column === "total_shipped" ? direction : null}
              onClick={() =>
                dispatch({ type: "CHANGE_SORT", column: "total_shipped" })
              }
            >
              Total Shipped
            </Table.HeaderCell>
            <Table.HeaderCell
              sorted={column === "total_acres" ? direction : null}
              onClick={() =>
                dispatch({ type: "CHANGE_SORT", column: "total_acres" })
              }
            >
              Total Acres Shipped
            </Table.HeaderCell>
          </Table.Row>
        </Table.Header>

        <Table.Body>
          {data.map((record, index) => {
            total_count += record.total_shipped;
            total_acres += record.total_acres;
            return (
              <Table.Row key={index}>
                <Table.Cell>{record.state}</Table.Cell>
                <Table.Cell>{record.month}</Table.Cell>
                <Table.Cell>{record.total_shipped}</Table.Cell>
                <Table.Cell>{record.total_acres.toFixed(3)}</Table.Cell>
              </Table.Row>
            );
          })}
        </Table.Body>
        <Table.Footer>
          <Table.Row>
            <Table.HeaderCell colSpan="2" textAlign="right">
              <b>Totals</b>
            </Table.HeaderCell>
            <Table.HeaderCell>
              <b>{total_count}</b>
            </Table.HeaderCell>
            <Table.HeaderCell>
              <b>{total_acres.toFixed(3)}</b>
            </Table.HeaderCell>
          </Table.Row>
        </Table.Footer>
      </Table>
    </div>
  );
}

function RenderNAIPTable({ company, records }) {
  const [state, dispatch] = React.useReducer(tableSortReducer, {
    column: null,
    data: records,
    direction: null,
  });
  const { column, data, direction } = state;

  let total_count = 0;

  // console.log("TotalDeliveryByStateAndContractorTable", {
  //   company,
  //   records,
  //   data,
  // });

  return (
    <div className="table-overflow">
      <Table
        unstackable
        sortable
        celled
        striped
        key={company}
        textAlign="center"
      >
        <Table.Header>
          <Table.Row textAlign="left">
            <Table.HeaderCell colSpan="5">{company}</Table.HeaderCell>
          </Table.Row>
          <Table.Row>
            <Table.HeaderCell
              sorted={column === "state" ? direction : null}
              onClick={() => dispatch({ type: "CHANGE_SORT", column: "state" })}
            >
              State
            </Table.HeaderCell>
            <Table.HeaderCell
              sorted={column === "month" ? direction : null}
              onClick={() => dispatch({ type: "CHANGE_SORT", column: "month" })}
            >
              Month
            </Table.HeaderCell>
            <Table.HeaderCell
              sorted={column === "total_shipped" ? direction : null}
              onClick={() =>
                dispatch({ type: "CHANGE_SORT", column: "total_shipped" })
              }
            >
              Total Shipped
            </Table.HeaderCell>
          </Table.Row>
        </Table.Header>

        <Table.Body>
          {data.map((record, index) => {
            total_count += record.total_shipped;
            total_acres += record.total_acres;
            return (
              <Table.Row key={index}>
                <Table.Cell>{record.state}</Table.Cell>
                <Table.Cell>{record.month}</Table.Cell>
                <Table.Cell>{record.total_shipped}</Table.Cell>
              </Table.Row>
            );
          })}
        </Table.Body>
        <Table.Footer>
          <Table.Row>
            <Table.HeaderCell colSpan="2" textAlign="right">
              <b>Totals</b>
            </Table.HeaderCell>
            <Table.HeaderCell>
              <b>{total_count}</b>
            </Table.HeaderCell>
          </Table.Row>
        </Table.Footer>
      </Table>
    </div>
  );
}
